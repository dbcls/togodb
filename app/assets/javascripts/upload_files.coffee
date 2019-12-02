$ ->
  $("#table_selector").change ->
    table_name = $(this).val()
    location.href = "/upload_files/#{table_name}"
