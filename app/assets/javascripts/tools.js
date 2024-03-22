function Tab(tab_id, delegate) {
    this.$tab = $('#' + tab_id);
    this.$tab_content = $('#' + tab_id + '_contents');
    this.tabDelegate = delegate;

    if (tab_id === 'entry_code_body' || tab_id === 'entry_code_header' || tab_id === 'entry_code_css') {
        this.$other_content = $('#entry_btns');
    } else if (tab_id === 'table_code_body' || tab_id === 'table_code_header' || tab_id === 'table_code_css') {
        this.$other_content = $('#table_btns');
    } else {
        this.$other_content = null;
    }

    const self = this;
    this.$tab.on('click', function () {
        const clicked_tab = self.$tab.attr("id");

        self.tabDelegate.inActiveAll();

        if (self.$tab.hasClass('active')) {
            self.$tab.removeClass('active');
            self.$tab_content.hide();
            if (self.$other_content) {
                self.$other_content.hide();
            }
        } else {
            if (clicked_tab === 'entry_edit') {
                $("#columns_settings_contents").prependTo($("#entry_code_columns_settings_contents"));
                $("#columns_link_contents").prependTo($("#entry_code_columns_link_contents"));
            } else if (clicked_tab === 'table_edit') {
                $("#columns_settings_contents").prependTo($("#table_code_columns_settings_contents"));
                $("#columns_link_contents").prependTo($("#table_code_columns_link_contents"));
            }

            self.$tab.addClass('active');
            self.$tab_content.show();
            if (self.$other_content) {
                self.$other_content.show();
            }
        }
    });
}

Tab.prototype.inActive = function () {
    this.$tab.removeClass('active');
    this.$tab_content.hide();

    if (this.$other_content) {
        this.$other_content.hide();
    }
};

function TabManager() {
    this.$tabs = [];
}

TabManager.prototype.inActiveAll = function () {
    for (let i = 0; i < this.$tabs.length; i++) {
        const tab = this.$tabs[i];
        tab.inActive();
    }
};

TabManager.prototype.addTab = function ($tab) {
    this.$tabs.push($tab);
};
