$ ->
  editor = CodeMirror.fromTextArea document.getElementById("sparql-query"), {
    mode: "application/sparql-query",
    matchBrackets: true,
    lineNumbers: true
  }

  $("#sparql-submit").bind "click", ->
    $("#sparql-result").hide()
    $("#sparql-running-icon").show()
