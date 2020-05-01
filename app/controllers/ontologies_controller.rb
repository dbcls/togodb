require 'open3'

class OntologiesController < ApplicationController
  before_action :set_table, only: %i[content]
  before_action :read_user_required, only: %i[content]

  before_action :set_work, only: %i[content]
  before_action :set_namespace_setting, only: %i[update]

  def update
    if namespace_setting_params.key?(:ontology)
      @namespace_setting.update!(namespace_setting_params)
      flash[:msg] = 'Ontology saved successfully.'
    elsif namespace_setting_params.key?(:ontology_file)
      @namespace_setting.update!(
          ontology: ontology_file_contents,
          original_filename: namespace_setting_params[:ontology_file].original_filename
      )
      flash[:msg] = 'Ontology file was successfully uploaded.'
    end

    redirect_to namespace_path(@namespace_setting.work.name)
  end

  def content
    uri = "http://#{Togodb.app_server}/ontologies/#{@work.name}/#{params[:ontology_name]}#"
    namespace = Namespace.find_by(uri: uri)
    if namespace.nil?
      namespace = Namespace.find_by(prefix: @work.name)
    end

    if namespace.nil?
      head :not_found
    else
      namespace_setting = NamespaceSetting.find_by(work_id: @work.id, namespace_id: namespace.id)
      if namespace_setting.nil?
        head :not_found
      else
        render plain: namespace_setting.ontology
      end
    end
  end

  private

  def set_work
    @work = if params[:id] =~ /\A\d+\z/
              Work.find(params[:id])
            else
              Work.find_by(name: params[:id])
            end
  end

  def set_namespace_setting
    @namespace_setting = NamespaceSetting.find(params[:id])
  end

  def namespace_setting_params
    params.require(:namespace_setting).permit(:ontology_file, :ontology)
  end

  def ontology_file_contents
    namespace_setting_params[:ontology_file].read
  end

end
