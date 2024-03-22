document.addEventListener('DOMContentLoaded', () => {
    const tabManager = new TabManager();

    const tabColumnsSetting = new Tab("togodb_columns_basic", tabManager);
    const tabColumnsLink = new Tab("togodb_columns_link", tabManager);
    const tabColumnsGraph = new Tab("togodb_columns_graph", tabManager);

    tabManager.addTab(tabColumnsSetting);
    tabManager.addTab(tabColumnsLink);
    tabManager.addTab(tabColumnsGraph);
});
