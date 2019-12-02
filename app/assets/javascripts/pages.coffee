# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

page_types = ['body', 'header', 'css']

editManager = (prefix) ->
  tabManager = new TabManager()

  tabCodeBody = new Tab("#{prefix}_body", tabManager)
  tabCodeHeader = new Tab("#{prefix}_header", tabManager)
  tabCodeCss = new Tab("#{prefix}_css", tabManager)
  tabColumnsSettings = new Tab("#{prefix}_columns_settings", tabManager)
  tabColumnsLinks = new Tab("#{prefix}_columns_link", tabManager)

  editors = {}

  tabManager.addTab tabCodeBody
  tabManager.addTab tabCodeHeader
  tabManager.addTab tabCodeCss
  tabManager.addTab tabColumnsSettings
  tabManager.addTab tabColumnsLinks

  ###
  Define an extended mixed-mode that understands vbscript and
  leaves mustache/handlebars embedded templates in html mode
  ###
  mixedMode =
    name: "htmlmixed"
    lineNumbers: true
    scriptTypes: [
      { matches: /\/x-handlebars-template|\/x-mustache/i, mode: null },
      { matches: /(text|application)\/(x-)?vb(a|script)/i, mode: "vbscript" } ]

  $("##{prefix}_header_contents").hide 1
  $("##{prefix}_css_contents").hide 1

  editors["css"] = CodeMirror.fromTextArea document.getElementById("#{prefix}_textarea_css"),
    { mode: "text/css", lineNumbers:true, selectionPointer: true }


  editors["header"] = CodeMirror.fromTextArea document.getElementById("#{prefix}_textarea_header"),
    { mode: mixedMode, lineNumbers: true, selectionPointer: true }


  editors["body"] = CodeMirror.fromTextArea document.getElementById("#{prefix}_textarea_body"),
    { mode: mixedMode, lineNumbers: true, selectionPointer: true }

  return editors


selected_preview_tab = ->
  current_tab = $("#entry_table_tab").find(".togodb_tab.active").text()
  current_tab.toLowerCase()


selected_editor_tab = (preview_tab) ->
  current_tab = $("##{preview_tab}_edit_contents").find(".togodb_tab.active").text()
  current_tab.toLowerCase()


$ ->
  editors =
    "entry": editManager("entry_code")
    "table": editManager("table_code")

  tabManagerPrview = new TabManager()
  tabEntry = new Tab("entry_edit", tabManagerPrview)
  tabTable = new Tab("table_edit", tabManagerPrview)
  tabEntry.$other_content = $("#entry_code_preview")
  tabTable.$other_content = $("#table_code_preview")

  tabManagerPrview.addTab tabEntry
  tabManagerPrview.addTab tabTable

  $("#table_edit_contents").hide 1
  tabTable.$other_content.hide 1


  $("#table_selector").change ->
    selected_table = $(this).val()
    location.href = "/config_html/" + selected_table


  $(".preview-btn").click ->
    target = selected_preview_tab()
    columns_form_params = $("#tab-column-basic-form").serializeArray()
    link_form_params = $("#tab-column-link-form").serializeArray()

    param =
      "body": editors[target]["body"].getValue()
      "header": editors[target]["header"].getValue()
      "css": editors[target]["css"].getValue()
      "columns_settings": columns_form_params
      "columns_link": link_form_params

    $.post "/preview/#{target}/#{table_name}", param, (html)->
      previewFrame = document.getElementById "#{target}_code_preview"
      preview = previewFrame.contentDocument || previewFrame.contentWindow.document
      preview.open()
      preview.write html
      preview.close()


  $(".revert-default-btn").click ->
    return if confirm("Are you sure?") is false

    preview_tab = selected_preview_tab()
    target = selected_editor_tab(preview_tab)
    switch preview_tab
      when "entry"
        url = "/togodb_pages/#{page_id}/show_#{target}_default"
      when "table"
        url = "/togodb_pages/#{page_id}/view_#{target}_default"

    ajax_param =
      "url": url
      "type": "GET"
      "success": (data) ->
        editors[preview_tab][target].setValue data

    $.ajax ajax_param


  $(".link-other-type-selector").change ->
    column_id = $(this).data "colid"
    column_name = $(this).data "colname"
    selected = $("##{$(this).attr("id")} option:selected").val()
    link_text_field_id = "togodb_column_#{column_id}_html_link_prefix"
    if selected is ""
      $("##{link_text_field_id}").val ""
    else
      $("##{link_text_field_id}").val html_link[selected].replace("{id}", "{#{column_name}}")

