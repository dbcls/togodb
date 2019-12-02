module D2rqMapper
  include TogoMapper::Mapping

  def setup_new_mapping_for_togodb(table_name, user_id)
    db_config = Togodb.database_configuration

    ActiveRecord::Base.transaction do
      @work = Work.new(
        name: table_name,
        comment: "TogoDB - #{table_name}",
        user_id: user_id
      )
      @work.save!

      @db_connection = DbConnection.new(
        adapter:  db_config[:adapter],
        host:     db_config[:host],
        port:     db_config[:port],
        database: db_config[:database],
        username: db_config[:username],
        password: db_config[:password],
        work_id:  @work.id
      )
      @db_connection.save!

      Namespace.default_ns.each do |ns|
        NamespaceSetting.create!(work_id: @work.id, namespace_id: ns.id)
      end

      init_mapping(@db_connection, table_name)

      @work.mapping_updated = Time.now
      @work.save!

      # Create ontology_record to namespace_setting table
      prefix = @work.name
      uri = "http://#{Togodb.app_server}/ontology/#{@work.name}#"
      namespace = Namespace.find_or_create_by(prefix: prefix, uri: uri, is_default: false)
      NamespaceSetting.create!(
          work_id: @work.id,
          namespace_id: namespace.id,
          is_ontology: true,
          ontology: default_ontology(@work, ClassMap.first_class_map(@work.id))
      )
    end
  end

  def default_ontology(work, class_map)
    ontology_lines = []

    ontology_lines << '@prefix owl: <http://www.w3.org/2002/07/owl#> .'
    ontology_lines << "<http://#{Togodb.app_server}/#{work.name}> a owl:Class ."

    class_map.property_bridges_for_column.each do |property_bridge|
      next unless property_bridge.enable

      ontology_lines << "#{work.name}:#{property_bridge.column_name[0..3] == 'col_' ? property_bridge.column_name[4..-1] : property_bridge.column_name} a owl:DatatypeProperty ;"
      ontology_lines << "    rdfs:domain <http://#{Togodb.app_server}/#{work.name}> ;"
      ontology_lines << '    rdfs:range rdfs:Resource .'
    end

    ontology_lines.join("\n")
  end

end
