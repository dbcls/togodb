new_namespace_id = 1

$ ->
  $('[data-toggle="tooltip"]').tooltip()

  ontology_uri_query_string = (form_type, prefix, uri) ->
    "form_type=" + form_type + "&prefix=" + prefix + "&uri=" + encodeURIComponent(uri)

  ontology_upload_btn_click_action = (nss_id, prefix, uri) ->
    if (nss_id)
      $.getScript(edit_ontology_path(nss_id) + "?" + ontology_uri_query_string('upload', prefix, uri))
    else
      $.getScript(new_namespace_setting_path + "?" + ontology_uri_query_string('upload', prefix, uri))

  ontology_edit_btn_click_action = (nss_id, prefix, uri) ->
    if (nss_id)
      $.getScript(edit_ontology_path(nss_id) + "?" + ontology_uri_query_string('edit', prefix, uri))
    else
      $.getScript(new_namespace_setting_path + "?" + ontology_uri_query_string('edit', prefix, uri))

  bind_click_ontology_upload_btn = ->
    $("button.ontology-upload-btn").bind "click", ->
      upload_form_wrapper = $(this).parent("td").prev().children("div[class*='ontology-upload-wrapper']")
      edit_form_wrapper = $(this).parent("td").prev().children("div[class*='ontology-edit-wrapper']")
      edit_form_wrapper.hide()
      upload_form_wrapper.show()

  bind_click_ontology_edit_btn = ->
    $("button.ontology-edit-btn").bind "click", ->
      upload_form_wrapper = $(this).parent("td").prev().children("div[class*='ontology-upload-wrapper']")
      edit_form_wrapper = $(this).parent("td").prev().children("div[class*='ontology-edit-wrapper']")
      upload_form_wrapper.hide()
      edit_form_wrapper.show()

  bind_click_ontology_form_close_btn = ->
    $("button.ontology-form-close-btn").bind "click", ->
      form_wrapper = $(this).parents("div[class*='ontology-form-wrapper']:first")
      form_wrapper.hide()

  bind_click_ontology_delete_btn = ->
    $("button.btn-delete").bind "click", ->
      $(this).closest("tr").remove()

  bind_ontology_form_submit_action = ->
    $(".ontology-form").submit ->
      prefix = $(this).closest("td").prev("th").children("input[type='text']").val()
      uri = $(this).closest("td").children("input[type='text']").val()

      $(this).children("input[type='hidden'][name='prefix']").val(prefix)
      $(this).children("input[type='hidden'][name='uri']").val(uri)

  bind_click_ontology_action_buttons = (nss_id) ->
    bind_click_ontology_upload_btn(nss_id)
    bind_click_ontology_edit_btn(nss_id)
    bind_click_ontology_form_close_btn()
    bind_click_ontology_delete_btn()

  bind_ontology_form_submit_action()
  bind_click_ontology_action_buttons()

  $("#namespace-add-btn").bind "click", ->
    $.getScript new_namespace_form_url(new_namespace_id), ->
      new_namespace_id++
      bind_click_ontology_delete_btn()

  $("#namespaces-save-btn").bind "click", ->
    form_elements = $("#namespace-list").find('input:not([disabled])[type="text"]')
    form_elements.each ->
      $("#namespace-update-form").append('<input type="hidden" name="' + $(this).attr("name") + '" value="' + $(this).val() + '" />')
