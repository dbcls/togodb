Rails.autoloaders.each do |autoloader|
  autoloader.inflector.inflect(
    "db" => "DB",
    "db_connection" => "DBConnection",
    "sqlite" => "SQLite",
    "rdf" => "RDF",
    "rdf_generator" => "RDFGenerator",
    "rdf_xml_generator" => "RDFXmlGenerator",
    "togodb_db_metadata" => "TogodbDBMetadata",
    "togodb_db_metadata_doi" => "TogodbDBMetadataDoi",
    "togodb_db_metadata_pubmed" => "TogodbDBMetadataPubmed",
    "new_rdf_repository_job" => "NewRDFRepositoryJob"
  )
end
