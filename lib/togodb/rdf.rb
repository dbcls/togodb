module Togodb
  module RDF

    PREFIXES = {
        rdf: 'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
        rdfs: 'http://www.w3.org/2000/01/rdf-schema#',
        dc: 'http://purl.org/dc/elements/1.1/',
        dcterms: 'http://purl.org/dc/terms/',
        foaf: 'http://xmlns.com/foaf/0.1/',
        skos: 'http://www.w3.org/2004/02/skos/core#',
        pav: 'http://purl.org/pav/'
    }.freeze


    def statements_for_resource(record)
      statements = []

      # Resource Class
      statements << statement_for_resource_class if @table.has_resource_class?

      # Resource Label
      statements << statement_for_resource_label(record)

      statements
    end

    def rdf_statements(record, column)
      column_value = record[column.internal_name]
      return [] if column_value.to_s.strip.empty?

      if column.has_rdf_property?
        @property_uri = ::RDF::URI.new(column.rdf_p_property.strip)
        prefix = find_prefix(@property_uri.to_s)
        add_prefix(prefix[:prefix], prefix[:uri]) if prefix
      else
        @property_uri = predicate(column.name)
      end

      statements = if uri_cell?(record, column)
                     statements_for_uri_cell(record, column)
                   else
                     statements_for_literal_cell(record, column)
                   end

      if column.has_data_type?
        statements += statements_for_column_data_type(record, column)
      end

      statements
    end

    def statements_for_uri_cell(record, column)
      statements = []

      col_values = if column.id_separator.to_s.empty?
                     [record[column.internal_name]]
                   else
                     record[column.internal_name].split(column.id_separator)
                   end

      col_values.each do |column_value|
        object = ::RDF::URI.new(uri_value(record, column))
        statements << ::RDF::Statement.new(@resource_uri, @property_uri, object)

        if column.has_link?
          if column.other_type != 'PubMed' && column.other_type != 'DOI'
            statements << ::RDF::Statement.new(@resource_uri, ::RDF::RDFS.seeAlso, object)
          end
          statements << ::RDF::Statement.new(object, ::RDF::RDFS.label, column_value.to_s)
          add_prefix(:rdfs, 'http://www.w3.org/2000/01/rdf-schema#')
        end

        next unless column.has_rdf_class?

        # <column value (URI)> rdf:type <Class URI of RDF tab>
        class_uri = ::RDF::URI.new(column.rdf_o_class.strip)
        statements << ::RDF::Statement.new(object, ::RDF.type, class_uri)
        add_prefix(:rdf, 'http://www.w3.org/1999/02/22-rdf-syntax-ns#')
        prefix = find_prefix(class_uri.to_s)
        add_prefix(prefix[:prefix], prefix[:uri]) if prefix
      end

      # Primary key value --> dcterms:identifier
      statements << ::RDF::Statement.new(@resource_uri,
                                         ::RDF::URI.new("#{PREFIXES[:dcterms]}identifier"),
                                         ::RDF::Literal.new(record.id.to_s))

      statements
    end

    def statements_for_literal_cell(record, column)
      object = value2rdfobj(record, column)

      [::RDF::Statement.new(@resource_uri, @property_uri, object)]
    end

    def statement_for_resource_class
      pos = @table.resource_class.index(':')
      if pos.nil?
        class_uri = ::RDF::URI.new(@table.resource_class)
      else
        prefix = @table.resource_class[0 .. pos - 1].to_sym
        v = @table.resource_class[pos + 1 .. -1]
        class_uri = ::RDF::URI.new("#{PREFIXES[prefix]}#{v}")
      end

      prefix = find_prefix(class_uri.to_s)
      add_prefix(prefix[:prefix], prefix[:uri]) if prefix

      ::RDF::Statement.new(@resource_uri, ::RDF.type, class_uri)
    end

    def statement_for_resource_label(record)
      unless @table.has_resource_label?
        @table.resource_label = @table.resource_label_default
        @table.save
      end

      v = replace_colname_to_value(@table.resource_label, record, @columns)

      ::RDF::Statement.new(@resource_uri, ::RDF::RDFS.label, ::RDF::Literal.new(v.to_s))
    end

    def statements_for_column_data_type(record, column)
      statements = []

      Togodb::ColumnTypes.supported_types.each do |column_type|
        next unless column_type[:name] == column.other_type

        case column.other_type
        when 'PubMed', 'DOI'
          p = ::RDF::URI.new("#{PREFIXES[:dc]}references")
          prefix = find_prefix(p.to_s)
          add_prefix(prefix[:prefix], prefix[:uri]) if prefix
        else
          p = ::RDF::RDFS.seeAlso
        end

        v = record[column.internal_name]

        unless column_type[:link].to_s.strip.empty?
          statements << ::RDF::Statement.new(@resource_uri, p,
                                             ::RDF::URI.new(column_type[:link].gsub('{id}', v.to_s)))
        end

        unless column_type[:identifiers_org].to_s.strip.empty?
          statements << ::RDF::Statement.new(@resource_uri, p,
                                             ::RDF::URI.new(column_type[:identifiers_org].gsub('{id}', v.to_s)))
        end

        break
      end

      statements
    end

    def statements_for_version_info
      subject = ::RDF::URI("http://#{Togodb.app_server}/db/#{@table.name}")

      num_releases = TogodbDataReleaseHistory.where(dataset_id: @dataset.id, status: 'SUCCESS').count
      released_at = Time.now
      released_at = released_at.utc unless released_at.utc?

      [
          ::RDF::Statement(subject,
                           ::RDF::URI("#{PREFIXES[:pav]}version"),
                           ::RDF::Literal((num_releases + 1).to_s)),
          ::RDF::Statement(subject,
                           ::RDF::URI("#{PREFIXES[:pav]}lastUpdateOn"),
                           ::RDF::Literal::DateTime.new(released_at))
      ]
    end

    def subject(id)
      ::RDF::URI.new("http://#{Togodb.app_server}/entry/#{@table.name}/#{id}")
    end

    def predicate(colname)
      ::RDF::URI.new("http://#{Togodb.app_server}/ontology/#{@table.name}##{colname}")
    end

    def find_prefix(uri)
      prefix = nil

      PREFIXES.each do |p, u|
        pos = uri.index(u)
        if pos == 0
          prefix = { prefix: p, uri: u }
          break
        end
      end

      prefix
    end

    def add_prefix(prefix, uri)
      @namespace[prefix.to_sym] = ::RDF::URI(uri)
    end

    def value2rdfobj(record, column)
      value = record[column.internal_name]
      if value.nil?
        rdfobj = ::RDF::Literal.new('')
      else
        if value.kind_of?(String)
          if column.has_link?
            uri = replace_colname_to_value(column.html_link_prefix, record, @columns)
            rdfobj = ::RDF::URI.new(uri)
            prefix = find_prefix(uri)
            add_prefix(prefix[:prefix], prefix[:uri]) if prefix
          else
            rdfobj = if uri?(value)
                       ::RDF::URI.new(value)
                     else
                       ::RDF::Literal.new(value)
                     end
          end
        else
          case column['type']
          when 'date'
            rdfobj = ::RDF::Literal.new(value.to_s, datatype: ::RDF::XSD.date)
          when 'datetime'
            rdfobj = ::RDF::Literal.new(value.to_s.split(/ /)[0 .. 1].join('T'), datatype: ::RDF::XSD.dateTime)
          when 'timestamp with time zone'
            rdfobj = ::RDF::Literal.new(value, datatype: ::RDF::XSD.dateTime)
          else
            rdfobj = ::RDF::Literal.new(value)
          end
        end
      end

      rdfobj
    end

    def rdfobj2ttlobj(rdfobj)
      if rdfobj.instance_of?(::RDF::URI)
        str = "<#{rdfobj.to_s}>"
      elsif rdfobj.instance_of?(::RDF::Literal::Integer) || rdfobj.instance_of?(::RDF::Literal::Double) || rdfobj.instance_of?(::RDF::Literal::Decimal || rdfobj.instance_of?(::RDF::Literal::Boolean))
        str = rdfobj.to_s
      elsif rdfobj.instance_of?(::RDF::Literal::Date)
        str = %Q|"#{rdfobj}"^^<http://www.w3.org/2001/XMLSchema#date>|
      else
        str = escape_for_ttl(rdfobj.to_s)
        str = if /(\r|\n)/ =~ str
                '"""' + str + '"""'
              else
                '"' + str + '"'
              end
      end

      str
    end

    def escape_for_ttl(str)
      str.gsub(/[\\\"]/) { |c| "\\#{c}" }
    end

    def uri_cell?(record, column)

      value = record[column.internal_name].to_s
      uri = URI.parse(value)
      if uri.scheme.to_s == 'http'
        true
      else
        link = column.html_link_prefix
        link && link.strip != ''
      end
    rescue
      link = column.html_link_prefix
      link && link.strip != ''
    end

    def uri?(str)
      uri = URI.parse(str)
      !uri.sheme.nil? && uri.scheme != ''
    rescue
      false
    end

    def uri_value(record, column)
      if column.has_link?
        replace_colname_to_value(column.html_link_prefix, record, @columns)
      else
        record[column.internal_name]
      end
    end

  end
end
