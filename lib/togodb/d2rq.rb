require 'rdf/turtle'

module Togodb
  class D2RQ
    PREFIXES = {
        rdf: 'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
        rdfs: 'http://www.w3.org/2000/01/rdf-schema#',
        dc: 'http://purl.org/dc/elements/1.1/',
        dcterms: 'http://purl.org/dc/terms/',
        foaf: 'http://xmlns.com/foaf/0.1/',
        skos: 'http://www.w3.org/2004/02/skos/core#',
        xsd: 'http://www.w3.org/2001/XMLSchema#',
        map: '#',
        d2rq: 'http://www.wiwiss.fu-berlin.de/suhl/bizer/D2RQ/0.1#',
        d2r: 'http://sites.wiwiss.fu-berlin.de/suhl/bizer/d2r-server/config.rdf#'
    }.freeze


    def initialize
    end

    def generate_mapping_file(table_name, output_file_path, connection_properties)
      table = Togodb::Table.where({ name: table_name }).first
      data_release_setting = Togodb::DataReleaseSetting.where({ table_id: table.id }).first

      return if data_release_setting.nil?

      RDF::Turtle::Writer.open(output_file_path, prefixes: PREFIXES.merge(togodb: togodb_uri(table.name))) do |writer|
        # Database connection (d2rq:Database)
        database_statements(connection_properties).each do |statement|
          writer << statement
        end

        # RDF resource (d2rq:ClassMap)
        class_map_statements(connection_properties[:database], table).each do |statement|
          writer << statement
        end

        # Adding properties to resources (d2rq:PropertyBridge)
        data_release_setting.column_list.each do |column|
          property_bridge_statements(table.name, column).each do |statement|
            writer << statement
          end

          unless column.html_link_prefix.blank?
            statements_for_html_link(table.name, column).each do |statement|
              writer << statement
            end
          else
            unless column.rdf_o_class.blank?
              statements_for_rdf_class_setting(table_name, column).each do |statement|
                writer << statement
              end
            end
          end
        end
      end
    end

    def database_statements(connection_properties)
      statements = []

      s = database_statement_subject

      statements << RDF::Statement(s, RDF.type, RDF::URI(d2rq_uri('Database')))
      statements << RDF::Statement(s, RDF::URI(d2rq_uri('jdbcDSN')), RDF::Literal("#{jdbc_dsn(connection_properties)}"))
      statements << RDF::Statement(s, RDF::URI(d2rq_uri('jdbcDriver')), RDF::Literal("#{jdbc_driver_by_rails_adapter(connection_properties[:adapter])}"))
      statements << RDF::Statement(s, RDF::URI(d2rq_uri('username')), RDF::Literal("#{connection_properties[:username]}"))
      statements << RDF::Statement(s, RDF::URI(d2rq_uri('password')), RDF::Literal("#{connection_properties[:password]}"))

      statements
    end

    def class_map_statements(db_name, table)
      statements = []

      s = class_map_statement_subject(table.name)

      statements << RDF::Statement(s, RDF.type, RDF::URI(d2rq_uri('ClassMap')))
      statements << RDF::Statement(s, RDF::URI(d2rq_uri('dataStorage')), database_statement_subject);
      statements << RDF::Statement(s, RDF::URI(d2rq_uri('class')), RDF::URI("#{togodb_uri(table.name)}#{class_name(table.name)}"))
      statements << RDF::Statement(s, RDF::URI(d2rq_uri('uriPattern')), class_map_uri_pattern(table))
      statements << RDF::Statement(s, RDF::URI(d2rq_uri('classDefinitionLabel')), RDF::Literal(table.name))

      statements
    end

    def property_bridge_statements(table_name, column)
      statements = []

      s = property_bridge_subject(table_name, column.name)

      statements << RDF::Statement(s, RDF.type, RDF::URI(d2rq_uri('PropertyBridge')))
      statements << RDF::Statement(s, d2rq_uri('belongsToClassMap'), class_map_statement_subject(table_name))
      statements << RDF::Statement(s, d2rq_uri('property'), property_bridge_predicate(table_name, column))
      statements << RDF::Statement(s, d2rq_uri('propertyDefinitionLabel'), RDF::Literal(column.label))

      if column.has_id_separator?
        joined_table = joined_table_name(table_name, column)
        statements << RDF::Statement(s, d2rq_uri('column'), RDF::Literal("#{joined_table}.value"))
        statements << RDF::Statement(s, d2rq_uri('join'), RDF::Literal("#{table_name}.id = #{joined_table}.#{table_name}_id"))
      else
        statements << RDF::Statement(s, d2rq_uri('column'), RDF::Literal("#{table_name}.#{column.internal_name}"))
      end

      datatype = xsd_datatype(column.type)
      if datatype
        statements << RDF::Statement(s, d2rq_uri('datatype'), datatype)
      end

      statements
    end

    def statements_for_html_link(table_name, column)
      statements = []

      table = Togodb::Table.where(name: table_name).first
      uri_pattern = column.html_link_prefix.gsub(/\{(.+)\}/) {
        cur_column = Togodb::Column.where(name: $1, table_id: table.id).first
        if cur_column and cur_column.has_id_separator?
          "@@#{joined_table_name(table_name, $1)}.value@@"
        else
          "@@#{table_name}.col_#{$1}@@"
        end
      }

      # ClassMap
      class_map_s = RDF::URI("#{PREFIXES[:map]}#{table_name}_#{column.name}__html_link_cm")
      statements << RDF::Statement(class_map_s, RDF.type, RDF::URI(d2rq_uri('ClassMap')))
      statements << RDF::Statement(class_map_s, RDF::URI(d2rq_uri('dataStorage')), database_statement_subject)
      statements << RDF::Statement(class_map_s, RDF::URI(d2rq_uri('uriPattern')), RDF::Literal(uri_pattern))

      if idorg_class = identifiers_org_class(column.html_link_prefix)
        statements << RDF::Statement(class_map_s, RDF::URI(d2rq_uri('class')), RDF::URI(idorg_class))
      end

      unless column.rdf_o_class.blank?
        statements << RDF::Statement(class_map_s, RDF::URI(d2rq_uri('class')), RDF::URI(column.rdf_o_class))
      end

      # PropertyBridge (for uri_pattern rdfs:label "column value")
      s = RDF::URI("#{PREFIXES[:map]}#{table_name}_#{column.name}__html_link_label_pb")
      statements << RDF::Statement(s, RDF.type, RDF::URI(d2rq_uri('PropertyBridge')))
      statements << RDF::Statement(s, RDF::URI(d2rq_uri('belongsToClassMap')), class_map_s)
      statements << RDF::Statement(s, RDF::URI(d2rq_uri('property')), RDF::RDFS.label)
      if column.has_id_separator?
        statements << RDF::Statement(s, RDF::URI(d2rq_uri('column')), RDF::Literal("#{joined_table_name(table_name, column)}.value"))
      else
        statements << RDF::Statement(s, RDF::URI(d2rq_uri('column')), RDF::Literal("#{table_name}.#{column.internal_name}"))
      end

      # PropertyBridge (for rdfs:seeAlso)
      s = RDF::URI("#{PREFIXES[:map]}#{table_name}_#{column.name}__html_link_pb")
      statements << RDF::Statement(s, RDF.type, RDF::URI(d2rq_uri('PropertyBridge')))
      statements << RDF::Statement(s, RDF::URI(d2rq_uri('belongsToClassMap')), class_map_statement_subject(table_name))
      statements << RDF::Statement(s, RDF::URI(d2rq_uri('property')), RDF::RDFS.seeAlso)
      statements << RDF::Statement(s, RDF::URI(d2rq_uri('uriPattern')), RDF::Literal(uri_pattern))
      if column.has_id_separator?
        statements << RDF::Statement(s, RDF::URI(d2rq_uri('join')), RDF::Literal("#{table_name}.id = #{joined_table_name(table_name, column)}.#{table_name}_id"))
      end

      statements
    end

    def statements_for_rdf_class_setting(table_name, column)
      statements = []

      # ClassMap
      class_map_s = RDF::URI("#{PREFIXES[:map]}#{table_name}_#{column.name}__rdf_class_cm")
      statements << RDF::Statement(class_map_s, RDF.type, RDF::URI(d2rq_uri('ClassMap')))
      statements << RDF::Statement(class_map_s, RDF::URI(d2rq_uri('dataStorage')), database_statement_subject);
      statements << RDF::Statement(class_map_s, RDF::URI(d2rq_uri('uriColumn')), RDF::Literal("#{table_name}.#{column.internal_name}"))
      statements << RDF::Statement(class_map_s, RDF::URI(d2rq_uri('condition')), RDF::Literal("#{table_name}.#{column.internal_name} ~* '^[a-z][-+.0-9a-z]*?:\\/\\/[\\
                                                                                              \w/:%#\\$&\\?\\(\\)~\\.=\\+\\-]+$'"))

      # PropertyBridge
      s = RDF::URI("#{PREFIXES[:map]}#{table_name}_#{column.name}__rdf_class_pb")
      statements << RDF::Statement(s, RDF.type, RDF::URI(d2rq_uri('PropertyBridge')))
      statements << RDF::Statement(s, RDF::URI(d2rq_uri('belongsToClassMap')), class_map_s)
      statements << RDF::Statement(s, RDF::URI(d2rq_uri('property')), RDF.type)
      statements << RDF::Statement(s, RDF::URI(d2rq_uri('constantValue')), RDF::URI(column.rdf_o_class))

      statements
    end

    def jdbc_dsn(connection_properties)
      case connection_properties[:adapter]
      when 'mysql', 'mysql2'
      when 'postgresql'
        host = connection_properties[:host].blank? ? 'localhost' : connection_properties[:host]
        port = connection_properties[:port].blank? ? '5432' : connection_properties[:port]
        "jdbc:postgresql://#{host}:#{port}/#{connection_properties[:database]}"
      end
    end

    def jdbc_driver_by_rails_adapter(adapter)
      case adapter
      when 'mysql', 'mysql2'
      when 'postgresql'
        'org.postgresql.Driver'
      end
    end

    def database_statement_subject
      RDF::URI("#{PREFIXES[:d2rq]}database")
    end

    def class_map_statement_subject(table_name)
      RDF::URI("#{PREFIXES[:map]}#{table_name}")
    end

    def pk_column_name(table)
      pk_column_id = table.pkey_col_id
      if pk_column_id
        pk_column = Togodb::Column.find(pk_column_id)
        pk_col_name = pk_column.internal_name
      else
        pk_col_name = 'id'
      end

      pk_col_name
    end

    def class_map_uri_pattern(table)
      RDF::Literal("http://togodb.org/entry/#{table.name}/@@#{table.name}.#{pk_column_name(table)}@@")
    end

    def property_bridge_subject(table_name, column_name)
      RDF::URI("#{PREFIXES[:map]}#{table_name}_#{column_name}")
    end

    def property_bridge_predicate(table_name, column)
      if column.rdf_p_property.blank?
        RDF::URI("#{togodb_uri(table_name)}#{column.name}")
      else
        RDF::URI(column.rdf_p_property)
      end
    end

    def class_name(s)
      s.sub(/./, &:upcase)
    end

    def d2rq_uri(vocab)
      "#{PREFIXES[:d2rq]}#{vocab}"
    end

    def togodb_uri(table_name)
      "http://togodb.org/ontology/#{table_name}#"
    end

    def identifiers_org_class(s)
      if %r{\Ahttp\://identifiers\.org/([^/]+)/} =~ s
        "http://identifiers.org/#{$1}"
      else
        nil
      end
    end

    def xsd_datatype(togodb_column_type)
      case togodb_column_type
      when 'string'
        nil
      when 'text'
        nil
      when 'integer'
        RDF::XSD.integer
      when 'float'
        RDF::XSD.float
      when 'double'
        RDF::XSD.double
      when 'decimal'
        RDF::XSD.decimal
      when 'boolean'
        RDF::XSD.boolean
      when 'date'
        RDF::XSD.date
      when 'datetime'
        RDF::XSD.dateTime
      else
        nil
      end
    end

  end

end
