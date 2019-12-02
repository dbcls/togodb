module Togodb
  class Metadata

    def initialize(id)
      @metadata = TogodbDbMetadata.find(id)
      @pubmeds = TogodbDbMetadataPubmed.where(db_metadata_id: @metadata.id)
      @dois = TogodbDbMetadataDoi.where(db_metadata_id: @metadata.id)
    end

    def generate_rdf(format)
      rdf_generator = Togodb::Metadata::RDFGenerator.new(@metadata, @pubmeds, @dois)

      rdf_generator.generate(format)
    end

  end
end
