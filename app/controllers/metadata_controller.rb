class MetadataController < ApplicationController

  def update
    @msg_item_id = "db-metadata-update-msg"

    begin
      metadata = TogodbDBMetadata.find(params[:id])
    rescue
      message = "ERROR: Database metadata not found."
      render partial: 'set_error_message', locals: { element_id: @msg_item_id, message: message }
      return
    end

    begin
      table = TogodbTable.find(metadata.table_id)
    rescue
      message = "ERROR: Database not found."
      render partial: 'set_error_message', locals: { element_id: @msg_item_id, message: message }
      return
    end
=begin
    unless allow_execute?(current_user, table)
      message = "ERROR: You don't have permission to access this page."
      render partial: 'set_error_message', locals: { element_id: @msg_item_id, message: message }
      return
    end
=end
    begin
      metadata.update!(metadata_params)

      TogodbDBMetadataPubmed.where(db_metadata_id: metadata.id).delete_all
      if params[:pubmeds]
        params[:pubmeds].each do |pubmed|
          TogodbDBMetadataPubmed.create!(
              pubmed_id: pubmed,
              db_metadata_id: metadata.id
          )
        end
      end

      TogodbDBMetadataDoi.where(db_metadata_id: metadata.id).delete_all
      if params[:dois]
        params[:dois].each do |doi|
          TogodbDBMetadataDoi.create!(
              doi: doi,
              db_metadata_id: metadata.id
          )
        end
      end
    rescue => e
      message = "ERROR: #{e.message}"
      render partial: 'set_error_message', locals: { element_id: @msg_item_id, message: message }
    end
  end

  private

  def metadata_params
    params.require(:togodb_db_metadata).permit(
        :title,
        :description,
        :creator,
        :creative_commons,
        :licence,
        :confirm_license,
        :literature_reference,
        :pubmed,
        :doi
    )
  end

end
