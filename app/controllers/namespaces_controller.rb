require 'togo_mapper/namespace'

class NamespacesController < D2rqMapperController
  protect_from_forgery

  include TogoMapper::Namespace

  before_action :set_work, except: [:new_namespace_form, :add_form, :ontology_file_upload_form]
  before_action :read_user_required, only: [:show]
  before_action :execute_user_required, only: [:update]
  before_action :set_html_body_class

  layout 'd2rq_mapper'

  def show
    @class_map = ClassMap.first_class_map(@work.id)
    @enabled_class_maps = ClassMap.table_derived(@work.id).select(&:enable)
    @namespaces = namespaces_by_namespace_settings(@work.id)
  end

  def update
    validate_posted_data

    notice_message = "<br />#{@warnings.join('<br />')}"
    error_message = "<br />#{@errors.join('<br />')}"

    unless posted_data_error?
      updated_namespace_setting_ids = []
      ActiveRecord::Base.transaction do
        if params[:new_namespaces]
          # New prefix and uri is specified.
          params[:new_namespaces].to_unsafe_h.keys.each do |id|
            prefix = params[:new_namespaces][id]['prefix']
            uri = params[:new_namespaces][id]['uri']
            next if prefix.blank? || uri.blank?

            namespace = Namespace.find_by(prefix: prefix, uri: uri)
            if namespace.nil?
              namespace = Namespace.create!(prefix: prefix, uri: uri, is_default: false)
            end

            namespace_setting = NamespaceSetting.create!(work_id: @work.id, namespace_id: namespace.id)
            updated_namespace_setting_ids << namespace_setting.id
          end
        end

        if params[:namespace_settings]
          # Existing prefix and uri
          params[:namespace_settings].to_unsafe_h.keys.each do |namespace_setting_id|
            updated_namespace_setting_ids << namespace_setting_id.to_i
            prefix = params[:namespace_settings][namespace_setting_id]['prefix']
            uri = params[:namespace_settings][namespace_setting_id]['uri']
            namespace_setting = NamespaceSetting.find(namespace_setting_id)
            namespace = Namespace.find_by(prefix: prefix, uri: uri)
            if namespace.nil?
              namespace = Namespace.create!(prefix: prefix, uri: uri, is_default: false)
            end
            namespace_setting.update!(work_id: @work.id, namespace_id: namespace.id)
          end
        end

        # Delete NamespaceSetting
        namespace_setting_ids_for_delete = NamespaceSetting.where(work_id: @work.id).select do |namespace_setting|
          !namespace_setting.is_ontology && !namespace_setting.is_default
        end.map(&:id) - updated_namespace_setting_ids
        NamespaceSetting.where(id: namespace_setting_ids_for_delete).delete_all

        save_mapping_updated_time
      end
    end

    if posted_data_error?
      flash[:err] = error_message
    else
      success_message = 'Namespace prefixes and URIs have been saved successfully.'
      if @warnings.empty?
        flash[:msg] = success_message
      else
        @status = 'notice'
        flash[:notice] = "#{notice_message}<br /><br />#{success_message}"

      end
    end

    redirect_to namespace_url(@work.name)
  end

  def new_namespace_form
    @id = params[:id]
  end

  private

  def validate_posted_data
    @errors = []
    @warnings = []

    uri = {}
    prefixes = []
    params[:prefix]&.zip(params[:uri])&.each do |ns|
      next if ns[0].blank?

      if uri.key?(ns[1])
      else
        uri[ns[1]] = [] unless uri.key?(ns[1])
      end
      uri[ns[1]] << ns[0]

      if prefixes.include?(ns[0])
        @errors << "The requested prefix #{ns[0]} is redefined as different URI."
      else
        prefixes << ns[0]
      end
    end

    @warnings = duplicated_uri_warnings(uri)
  end

  def duplicated_uri_warnings(uri_prefixes)
    lines = []
    uri_prefixes.keys.each do |uri|
      next if uri_prefixes[uri].size < 2
      lines << "The requested URI #{uri} was already saved as another prefix. (Prefixes: #{uri_prefixes[uri].join(', ')})"
    end

    lines
  end

  def posted_data_error?
    !@errors.empty?
  end

  def set_html_body_class
    @html_body_class = 'page-namespaces'
  end

end
