# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/
init_release_list_size = false
@DataSet = {
  included_container_selector: "ul#ds-included-columns"
  omitted_container_selector: "ul#ds-omitted-columns"

  included_container: ->
    $(DataSet.included_container_selector)

  omitted_container: ->
    $(DataSet.omitted_container_selector)

  included_column_li: ->
    $(DataSet.included_container_selector + " > li")

  omitted_column_li: ->
    $(DataSet.omitted_container_selector + " > li")

  all_column_li: ->
    $(DataSet.included_container_selector + " > li, " +  DataSet.omitted_container_selector + " > li")

  move_all_columns: (container) ->
    lis = new Array()
    DataSet.all_column_li().each ->
      lis.push($(this))
      $(this).detach();
    lis.sort( (a, b) -> Number(a.attr("id")) - Number(b.attr("id")) )
    for i in [0 ... lis.length - 1]
      lis[i].appendTo container

  select_all: ->
    DataSet.move_all_columns DataSet.included_container()

  unselect_all: ->
    DataSet.move_all_columns DataSet.omitted_container()

  update_cols_list_size: ->
    ul1 = $(DataSet.included_container_selector)
    ul2 = $(DataSet.omitted_container_selector)

    width1 = $(ul1).width()
    width2 = $(ul2).width()
    if width1 < width2
      width = width2
    else
      width = width1

    height1 = $(ul1).height()
    height2 = $(ul2).height()
    height  = height1 + height2
    if height2 != 0
      height--;

    ul1.width(width).height(height)
    ul2.width(width).height(height)

  set_id: ->
    dataset_id = $("#togodb-column-dataset-selector option:selected").val()
    $("#togodb-column-release-hidden-dataset-id").val dataset_id

  set_name: ->
    $("#togodb-column-release-hidden-dataset-name").val $("#new_dataset_name").val()

  set_included_column_ids: ->
    column_ids = '';
    DataSet.included_column_li().each ->
      column_ids += $(this).attr("id") + ","

    $("input[type='hidden'].dataset-columns").val(column_ids.slice(0, -1));

  create_dataset_filter_dialog: ->
    $("#togodb-config-release-filter").dialog {
      autoOpen: false,
      title: "Filter condition",
      width: 700,
      height: "auto"
    }

  create_new_dataset_dialog: ->
    $("#new-dataset-form").dialog {
      autoOpen: false,
      title: "Enter new dataset name",
      width: "auto",
      height: "auto",
      minHeight: 10,
      modal: true,
      close: (event, ui) ->
        $("#new-dataset-form-error-msg").html ""
        $("#new_dataset_name").val ""
    }

  create_delete_dataset_dialog: ->
    $("#delete-dataset-form").dialog {
      autoOpen: false,
      title: "Delete dataset",
      width: "auto",
      height: "auto",
      minHeight: 10,
      modal: true,
      close: (event, ui) ->
        $("#delete-dataset-form-error-msg").html ""
    }

  show_delete_button: ->
    $("#togodb-dataset-delete-submit").show()

  hide_delete_button: ->
    $("#togodb-dataset-delete-submit").hide()

  create_dialogs: ->
    DataSet.create_dataset_filter_dialog()
    DataSet.create_new_dataset_dialog()
    DataSet.create_delete_dataset_dialog()
    
  destroy_dialogs: ->
    $("#togodb-config-release-filter").dialog "destroy"
    $("#new-dataset-form").dialog "destroy"
    $("#delete-dataset-form").dialog "destroy"
    
  set_dataset_ui_callbacks: ->
    $("select#togodb-column-dataset-selector").on "change", ->
      dataset_id = $(this).find(":selected").val()
      $.getScript("/togodb_datasets/" + dataset_id + "/redraw")

    $("#togodb-dataset-new-submit").on "click", ->
      $("#new-dataset-form").dialog "open"

    $("#new-dataset-form-cancel").bind "click", ->
      $("#new-dataset-form").dialog "close"

    $("#togodb-dataset-delete-submit").on "click", ->
      $("#delete-dataset-form").dialog "open"

    $("#delete-dataset-form-cancel").bind "click", ->
      $("#delete-dataset-form").dialog "close"

    $("#data-release-update-dataset-btn").on "click", ->
      $("#column_release_setting_msg").html("").removeClass("error-message").addClass("notice-message")
      DataSet.set_included_column_ids()

    $("#new-dataset-form-ok").on "click", ->
      DataSet.set_id();
      DataSet.set_name();
      DataSet.set_included_column_ids();

    $("#data-release-filter-dataset").on "click", ->
      $("#togodb-config-release-filter").dialog "open"

    $("#data-release-select-all").on "click", ->
      if confirm("All columns will be included.")
        DataSet.select_all()

    $("#data-release-unselect-all").on "click", ->
      if confirm("All columns will be omitted.")
        DataSet.unselect_all()
}

$ ->
  DataSet.create_dialogs()
  DataSet.set_dataset_ui_callbacks()
  $("#togodb-dataset-delete-submit").button()
  DataSet.hide_delete_button()
  $("#togodb-column-setting-release-tab").on "click", ->
    if !init_release_list_size
      DataSet.update_cols_list_size()
      init_release_list_size = true
