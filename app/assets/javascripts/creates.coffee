# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/
$ ->
  tabManager = new TabManager()

  tabLocalFile = new Tab("tab_local_file", tabManager)
  tabRemoteFile = new Tab("tab_remote_file", tabManager)

  tabManager.addTab(tabLocalFile)
  tabManager.addTab(tabRemoteFile)
