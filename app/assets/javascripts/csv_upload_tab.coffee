$ ->
  tabManager = new TabManager()

  tabLocalFile = new Tab "tab_local_file", tabManager
  tabRemoteFile = new Tab "tab_remote_file", tabManager

  tabManager.addTab tabLocalFile
  tabManager.addTab tabRemoteFile
