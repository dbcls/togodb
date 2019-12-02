@DatabaseCopy = {
  copydb_progress_handle: null

  track_progress: (key) ->
    DatabaseCopy.copydb_progress_handle = setInterval "DatabaseCopy.get_populated_percentage('" + key + "')", 1000

  get_populated_percentage: (key) -> 
    $.ajax {
      url: "/tables/" + key + "/copied_percentage"
      type: "GET"
      dataType: "text"
      success: (obj) ->
        percentage = parseInt(obj)
        if percentage > 0
          $("#copy-db-progress-message").html "Copying database data ..."
          $("#copy-db-progressbar").css "width", "#{300 * (percentage / 100)}px"
          $("#copy-db-percentage").text(obj + "%")

        if percentage is 100
          clearInterval DatabaseCopy.copydb_progress_handle
          DatabaseCopy.copydb_progress_handle = null
          $.getScript "/tables/" + key + "/copy_result"
    }
}

$ ->
  $('#contents_uploadcsv').hide()
  $('#contents_editheader').hide()
  $('#contents_editcolumn').hide()
  $('#contents_importdata').hide()

  $('#title_uploadcsv').addClass('inactive')
  $('#title_editheader').addClass('inactive')
  $('#title_editcolumn').addClass('inactive')
  $('#title_importdata').addClass('inactive')

  # Progress Bar
  ###
  $("#copy-db-progressbar").progressbar {
    disabled: false
    value: 0
  }
  ###

  # [Start copy] button
  $("#start-copy-btn").click ->
    $("#database-copy-progress-wrapper").show()
    $("#database-copy-message").hide()
    $("#database-copy-message").html ""
