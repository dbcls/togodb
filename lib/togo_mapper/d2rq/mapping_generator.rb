module TogoMapper
  module D2rq
    class MappingGenerator
      include TogoMapper::Mapping
      include TogoMapper::Namespace

      attr_writer :password, :configuration_property, :database_property

      PREFIXES = {
          map: '#',
          d2rq: 'http://www.wiwiss.fu-berlin.de/suhl/bizer/D2RQ/0.1#',
          jdbc: 'http://d2rq.org/terms/jdbc/'
      }.freeze


      def initialize
        @password = ''
        @serve_vocabulary = true

        @database_property = {}
        @configuration_property = {}

        @output_resource_class = true
      end

      def prepare_by_work(work)
        @work = work
        @class_maps = ClassMap.by_work_id(@work.id)
        @property_bridges = PropertyBridge.where(work_id: @work.id)
        @table_joins = TableJoin.by_work_id(@work.id)

        prepare
      end

      def prepare_by_class_map(class_map)
        @class_map = class_map
        @work = Work.find(class_map.work_id)

        prepare
      end

      def prepare_by_property_bridge(property_bridge)
        @property_bridge = property_bridge
        @work = Work.find(property_bridge.work_id)
        @output_resource_class = false

        prepare
      end

      def prepare_by_table_join(table_join)
        @table_join = table_join
        @work = Work.find(table_join.work_id)

        prepare
      end

      def prepare
        @db_connection = @work.db_connection
        @base_uri = @work.base_uri
        @namespaces = namespaces_by_namespace_settings(@work.id)

        @prefixes = {}
        @namespaces.each do |ns|
          @prefixes[ns[:prefix].to_sym] = ns[:uri]
        end

        @ignored_class_map_names = []

        maintain_consistency_with_rdb

        @db = TogoMapper::DB.new(@db_connection.connection_config)
        @tables = @db.tables
      end

      def generate
        RDF::Turtle::Writer.buffer(prefixes: @prefixes) do |writer|
          # d2rq:Database
          generate_database_mapping(writer)

          # ClassMaps
          @class_maps.each do |class_map|
            unless class_map.enable
              @ignored_class_map_names << class_map.map_name
              next
            end

            if !class_map.table_name.blank? && !@tables.include?(class_map.table_name)
              @ignored_class_map_names << class_map.map_name
              next
            end

            if class_map.class_map_property_settings.empty?
              @ignored_class_map_names << class_map.map_name
              next
            end

            unless class_map.property_setting_for_resource_identity
              @ignored_class_map_names << class_map.map_name
              next
            end

            generate_class_map_mapping(writer, class_map)
          end

          # PropertyBridges
          @property_bridges.each do |property_bridge|
            next unless property_bridge.enable
            next unless column_exists?(property_bridge)
            next if property_bridge.class_map.for_bnode? && property_bridge.for_label?
            next unless property_bridge.has_property?

            begin
              class_map = property_bridge.class_map
              next if @ignored_class_map_names.include?(class_map.map_name)
              next if !class_map.table_derived? && property_bridge.for_column?
              next if (refers_to_class_map = property_bridge.pbps_for_refers_to_class_map) && @ignored_class_map_names.include?(refers_to_class_map.value[4 .. -1])
            rescue ActiveRecord::RecordNotFound
              next
            end

            generate_property_bridge_mapping(writer, property_bridge)
          end

          # Table joins
          @table_joins.each do |table_join|
            generate_join_mapping(writer, table_join)
          end

          # Global configuration of the mapping engine
          generate_global_configuration(writer)
        end
      end

      def generate_by_class_map(include_db_mapping = false)
        RDF::Turtle::Writer.buffer(prefixes: @prefixes) do |writer|
          # d2rq:Database
          generate_database_mapping(writer) if include_db_mapping

          # ClassMap
          generate_class_map_mapping(writer, @class_map)

          # PropertyBridges
          @class_map.property_bridges.each do |property_bridge|
            next unless property_bridge.enable
            next unless column_exists?(property_bridge)
            next if property_bridge.class_map.for_bnode? && property_bridge.for_label?
            next unless property_bridge.has_property?

            begin
              class_map = property_bridge.class_map
              next if @ignored_class_map_names.include?(class_map.map_name)
              next if !class_map.table_derived? && property_bridge.for_column?
            rescue ActiveRecord::RecordNotFound
              next
            end

            generate_property_bridge_mapping(writer, property_bridge)
          end

          # Global configuration of the mapping engine
          generate_global_configuration(writer)
        end
      end

      def generate_by_property_bridge(include_db_mapping = false)
        RDF::Turtle::Writer.buffer(prefixes: @prefixes) do |writer|
          generate_database_mapping(writer) if include_db_mapping

          generate_class_map_mapping(writer, @property_bridge.class_map)
          generate_property_bridge_mapping(writer, @property_bridge)

          # Global configuration of the mapping engine
          generate_global_configuration(writer)
        end
      end

      def generate_by_table_join(include_db_mapping = false)
        RDF::Turtle::Writer.buffer(prefixes: @prefixes) do |writer|
          generate_database_mapping(writer) if include_db_mapping
          generate_class_map_mapping(writer, @table_join.class_map)
          generate_join_mapping(writer, @table_join)

          # Global configuration of the mapping engine
          generate_global_configuration(writer)
        end
      end

      def generate_database_mapping(writer)
        s = RDF::URI(map_uri('database'))

        writer << RDF::Statement(
            s,
            RDF.type,
            RDF::URI(d2rq_uri('Database')))

        writer << RDF::Statement(
            s,
            RDF::URI(d2rq_uri('jdbcDriver')),
            RDF::Literal(dbadapter2jdbcdriver(@db_connection.adapter))
        )

        writer << RDF::Statement(
            s,
            RDF::URI(d2rq_uri('jdbcDSN')),
            RDF::Literal(jdbc_dsn(@db_connection))
        )

        @database_property.each do |property, value|
          writer << RDF::Statement(
              s,
              RDF::URI(d2rq_uri(property)),
              RDF::Literal(value)
          )
        end

        unless @db_connection.adapter == 'sqlite3'
          writer << RDF::Statement(
              s,
              RDF::URI(d2rq_uri('username')),
              RDF::Literal(@db_connection.username)
          )
          writer << RDF::Statement(
              s,
              RDF::URI(d2rq_uri('password')),
              RDF::Literal(@password)
          )
        end
      end

      def generate_class_map_mapping(writer, class_map)
        s = RDF::URI(map_uri(class_map.map_name))
        writer << RDF::Statement(
            s,
            RDF.type,
            RDF::URI(d2rq_uri('ClassMap'))
        )
        writer << RDF::Statement(
            s,
            RDF::URI(d2rq_uri('dataStorage')),
            RDF::URI(map_uri('database'))
        )

        class_map.class_map_property_settings.each do |cmps|
          class_map_property = cmps.class_map_property
          next unless class_map_property
          next if cmps.value.blank?
          next if class_map.for_join? && cmps.class_map_property.property == 'd2rq:class'
          #next if class_map.for_bnode? && cmps.class_map_property.property == "d2rq:class"
          next if !@output_resource_class && cmps.class_map_property.property == 'd2rq:class'

          if class_map_property.property == 'd2rq:uriPattern'
            writer << RDF::Statement(
                s,
                RDF::URI(d2rq_property_uri(class_map_property.property)),
                RDF::Literal(uri_pattern_value(refine_d2rq_pattern(cmps.value)))
            )
          elsif class_map_property.is_literal
            writer << RDF::Statement(
                s,
                RDF::URI(d2rq_property_uri(class_map_property.property)),
                RDF::Literal(cmps.value)
            )
          else
            writer << RDF::Statement(
                s,
                RDF::URI(d2rq_property_uri(class_map_property.property)),
                RDF::URI(fqdn(@prefixes, cmps.value))
            )
          end
        end
      end

      def generate_property_bridge_mapping(writer, property_bridge)
        s = RDF::URI(map_uri(property_bridge.map_name))
        writer << RDF::Statement(
            s,
            RDF.type,
            RDF::URI(d2rq_uri('PropertyBridge'))
        )
        property_bridge.property_bridge_property_settings.each do |pbps|
          next if pbps.value.blank?

          if pbps.property_bridge_property.property == 'd2rq:belongsToClassMap'
            writer << RDF::Statement(
                s,
                RDF::URI(d2rq_property_uri(pbps.property_bridge_property.property)),
                RDF::URI(map_uri(pbps.value))
            )
          elsif pbps.property_bridge_property.property == 'd2rq:uriPattern'
            writer << RDF::Statement(
                s,
                RDF::URI(d2rq_property_uri(pbps.property_bridge_property.property)),
                RDF::Literal(uri_pattern_value(refine_d2rq_pattern(pbps.value)))
            )
          elsif pbps.property_bridge_property.property == 'd2rq:pattern'
            writer << RDF::Statement(
                s,
                RDF::URI(d2rq_property_uri(pbps.property_bridge_property.property)),
                RDF::Literal(refine_d2rq_pattern(pbps.value))
            )
          else
            if pbps.property_bridge_property.is_literal
              writer << RDF::Statement(
                  s,
                  RDF::URI(d2rq_property_uri(pbps.property_bridge_property.property)),
                  RDF::Literal(pbps.value)
              )
            else
              writer << RDF::Statement(
                  s,
                  RDF::URI(d2rq_property_uri(pbps.property_bridge_property.property)),
                  RDF::URI(fqdn(@prefixes, pbps.value))
              )
            end
          end
        end
      end

      def generate_join_mapping(writer, table_join)
        subject_class_map = table_join.class_map
        return if @ignored_class_map_names.include?(subject_class_map.map_name)

        object_class_map = table_join.r_table
        property_bridges = PropertyBridge.where(
            class_map_id: subject_class_map.id,
            property_bridge_type_id: PropertyBridgeType.column.id
        )
        property_bridges.each do |property_bridge|
          s = RDF::URI(map_uri(property_bridge.map_name))

          writer << RDF::Statement(
              s,
              RDF.type,
              RDF::URI(d2rq_uri('PropertyBridge'))
          )

          writer << RDF::Statement(
              s,
              RDF::URI(d2rq_property_uri('d2rq:belongsToClassMap')),
              RDF::URI(map_uri(subject_class_map.map_name))
          )

          property_bridge.predicate.each do |predicate_pbps|
            writer << RDF::Statement(
                s,
                RDF::URI(d2rq_property_uri('d2rq:property')),
                RDF::URI(fqdn(@prefixes, predicate_pbps.value))
            )
          end

          object_pbps = property_bridge.object_for_join
          if object_pbps.property_bridge_property.property == 'd2rq:refersToClassMap'
            writer << RDF::Statement(
                s,
                RDF::URI(d2rq_property_uri('d2rq:refersToClassMap')),
                RDF::URI(map_uri(object_class_map.map_name))
            )
          else
            if object_pbps.property_bridge_property.property == 'd2rq:uriPattern'
              o = RDF::Literal(uri_pattern_value(object_pbps.value))
            else
              o = RDF::Literal(object_pbps.value)
            end
            writer << RDF::Statement(
                s,
                RDF::URI(d2rq_property_uri(object_pbps.property_bridge_property.property)),
                o
            )
          end

          # SQL WHERE condition
          condition_pbps = PropertyBridgePropertySetting.where(
              property_bridge_id: property_bridge.id,
              property_bridge_property_id: PropertyBridgeProperty.condition.id
          ).first
          if condition_pbps && !condition_pbps.value.blank?
            writer << RDF::Statement(
                s,
                RDF::URI(d2rq_property_uri('d2rq:condition')),
                RDF::Literal(condition_pbps.value)
            )
          end

          # d2rq:join
          if table_join.multiple_join?
            itbl_class_map = table_join.i_table

            writer << RDF::Statement(
                s,
                RDF::URI(d2rq_property_uri('d2rq:join')),
                RDF::Literal("#{table_join.l_table.table_name}.#{table_join.l_column.column_name} = #{itbl_class_map.table_name}.#{table_join.i_l_column.column_name}")
            )
            writer << RDF::Statement(
                s,
                RDF::URI(d2rq_property_uri('d2rq:join')),
                RDF::Literal("#{itbl_class_map.table_name}.#{table_join.i_r_column.column_name} = #{table_join.r_table.table_name}.#{table_join.r_column.column_name}")
            )
          else
            writer << RDF::Statement(
                s,
                RDF::URI(d2rq_property_uri('d2rq:join')),
                RDF::Literal("#{table_join.l_table.table_name}.#{table_join.l_column.column_name} = #{object_class_map.table_name}.#{table_join.r_column.column_name}")
            )
          end
        end
      end

      def generate_global_configuration(writer)
        return if @configuration_property.empty?

        s = RDF::URI(map_uri('Configuration'))
        writer << RDF::Statement(
            s,
            RDF.type,
            RDF::URI(d2rq_uri('Configuration')),
        )

        @configuration_property.each do |property, value|
          writer << RDF::Statement(
              s,
              RDF::URI(d2rq_uri(property)),
              RDF::Literal(value)
          )
        end
      end

      def uri_pattern_value(value)
        if /\A<.*>\z/ =~ value
          pos = value.index(':')
          if pos
            value[1 .. -2]
          else
            "#{@base_uri}#{value[1 .. -2]}"
          end
        elsif /\A".*"\z/ =~ value
          value[1 .. -2]
        else
          pos = value.index(':')
          if pos
            prefix = value[0 .. pos - 1]
            if @prefixes.key?(prefix.to_sym)
              "#{@prefixes[prefix.to_sym]}#{value[pos + 1 .. -1]}"
            else
              value
            end
          else
            value
          end
        end
      end

      def d2rq_uri(vocab)
        "#{PREFIXES[:d2rq]}#{vocab}"
      end

      def map_uri(vocab)
        "#{PREFIXES[:map]}#{vocab}"
      end

      def d2rq_property_uri(v)
        v.sub(/\Ad2rq\:/, PREFIXES[:d2rq])
      end

      def fqdn(prefixes, v)
        if /\A(.+)\:/ =~ v && prefixes.key?($1.to_sym)
          v.sub(/\A(.+)\:/) { prefixes[$1.to_sym] }
        else
          v
        end
      end

      def dbadapter2jdbcdriver(adapter)
        case adapter
        when 'mysql2'
          'com.mysql.jdbc.Driver'
        when 'postgresql'
          'org.postgresql.Driver'
        when 'sqlite3'
          'org.sqlite.JDBC'
        else
          ''
        end
      end

      def column_exists?(property_bridge)
        if property_bridge.for_column?
          @db.columns(property_bridge.class_map.table_name).include?(property_bridge.column_name)
        else
          true
        end
      end

      def jdbc_dsn(db_connection)
        case db_connection.adapter
        when 'mysql2'
          host = db_connection.host == 'localhost' ? '127.0.0.1' : db_connection.host
          port = db_connection.port == 3306 ? '' : ":#{db_connection.port}"
          "jdbc:mysql://#{host}#{port}/#{db_connection.database}"
        when 'postgresql'
          host = db_connection.host
          port = db_connection.port == 5432 ? '' : ":#{db_connection.port}"
          "jdbc:postgresql://#{host}#{port}/#{db_connection.database}"
        when 'sqlite3'
          "jdbc:sqlite:#{db_connection.database}"
        else
          ''
        end
      end

      def refine_d2rq_pattern(s)
        s.gsub(/@@(.+?)@@/) do
          table, column = $1.split('.')
          if !column.blank?
            togodb_table = TogodbTable.find_by(name: table)
            togodb_column = TogodbColumn.find_by(table_id: togodb_table.id, name: column)
            column_internal_name = if togodb_column.nil? && column == 'id'
                                     'id'
                                   else
                                     togodb_column.internal_name
                                   end
            "@@#{table}.#{column_internal_name}@@"
          else
            "@@#{$1}@@"
          end
        end
      rescue
        s
      end

    end
  end
end
