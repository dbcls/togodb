module OntologiesHelper

  def form_url
    if @namespace_setting.id
      namespace_setting_path(@namespace_setting)
    else
      namespace_namespace_settings_path(@work)
    end
  end

  def form_embed_elem_id(form_type)
    case form_type
    when 'upload'
      'upload-ontology-file-form'
    when 'edit'
      'edit-ontology-form'
    end
  end

  def submit_btn_label
    case @form_type
    when 'upload'
      'Upload a ontology file'
    when 'edit'
      'Save'
    end
  end

  def form_close_btn_id
    case @form_type
    when 'upload'
      'ontology-file-upload-close-btn'
    when 'edit'
      'ontology-edit-close-btn'
    end
  end

end
