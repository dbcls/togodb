$ ->
  editor = CodeMirror.fromTextArea document.getElementById("code"), {
    mode: "text/turtle",
    matchBrackets: true,
    lineNumbers: true,
    lineWrapping: true
  }
