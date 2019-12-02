# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

@notice_message = (msg_id, msg) ->
  $("#" + msg_id).removeClass "error-message"
  $("#" + msg_id).addClass "notice-message"
  $("#" + msg_id).html msg

@error_message = (msg_id, msg) ->
  $("#" + msg_id).removeClass "notice-message"
  $("#" + msg_id).addClass "error-message"
  $("#" + msg_id).html msg

                            
init_add_column_dialog = ->
  $("#togodb-add-column-form").dialog { autoOpen: false, title: "Add column", width: "auto", height: "auto", minHeight: 80,  modal: true }
  $("#togodb-add-column-open-dialog-btn").on 'click', -> $("#togodb-add-column-form").dialog("open")
  $("#togodb-add-column-form-cancel-btn").on 'click', -> $("#togodb-add-column-form").dialog("close")
  return
		
$ ->
  ###
  $("#togodb-database-setting-tab").tabs()
  $("#togodb-column-setting-tab").tabs()
  # $("select").selectmenu()
  $("input[type='submit']").button()
  $("button").button()
  $("a.togodb-config-default-submit").button()
  $("a#copy-database-submit").button()
  $("a#append-database-submit").button()
  $("a#delete-database-submit").button()
  init_add_column_dialog()
  
  $('#db-operation-submit').on 'click', ->
    $("#db-operation-update-msg").html "&nbsp;"
    $("#db-operation-update-msg").removeClass "notice-message"
    $("#db-operation-update-msg").removeClass "error-message"
    $("#db-operation-update-msg").removeClass "warning-message"
    return

  $('#togodb-add-column-submit').on 'click', ->
    $("#add-column-dialog-message").html ""
    if confirm("Are you sure ?")
      notice_message "add_column_dialog_message", "Adding a column now. Please wait."
      return true
    else
      return false
  ###

  $("#table_selector").change ->
    selected_table = $(this).val()
    location.href = "/config/" + selected_table

  $('#togodb_table_enabled').on 'change', ->
    is_public = $('#togodb_table_enabled').val();
    if is_public is 'true'
      $('#sparql-endpoint-uri').show();
    else
      $('#sparql-endpoint-uri').hide();

  $('#search-user-submit').on 'click', ->
    $("#togodb-user-roles-new-user-update-button").hide();
    $.post "/config/#{$(this).data('configid')}/find_user", { login: $('#search-user-login').val() }

  $('#togodb-user-roles-new-user-update-button').on 'click', ->
    #$('#search-user-form').submit()
    $('body').removeClass 'modal-open'
    $('.modal-backdrop').remove()
    $('#search-user-modal').modal 'hide'

  $('#search-user-modal').on 'show.bs.modal', ->
    $('#search-user-login').val 'http://openid.dbcls.jp/user/'
    $('#search-user-result').html ''
    $("#togodb-user-roles-new-user-update-button").hide();

