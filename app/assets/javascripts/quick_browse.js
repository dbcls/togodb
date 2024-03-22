
const keyDownHandler = (event) => {
    switch(event.code) {
        case 'Space':
            event.preventDefault();
            onSpaceKeyPressed();
    }
}

const toggleQuickBrowse = () => {
    const quickBrowseDialogId = '#togodb-quickbrowse-' + database;
    if ($(quickBrowseDialogId).dialog('isOpen')) {
        $(quickBrowseDialogId).dialog('close');
    } else {
        // $.getScript('/entries/quickbrowse/' + database + '/' + 1, (data) => {
        //     eval(data);
        // });
        $(quickBrowseDialogId).dialog('open');
    }
}

const onSpaceKeyPressed = () => {
    toggleQuickBrowse();
}

document.addEventListener('DOMContentLoaded', () => {
    $('#togodb-quickbrowse-' + database).dialog({
        title: "QuickBrowse",
        autoOpen: false,
        width: 'auto',
        height: 'auto',
        position: {
            my: "left top",
            at: "left+20 top+20"
        },
        open: function (event) {
            // list_viewer.show_row_highlight();
        },
        close: function (event) {
            // list_viewer.hide_row_highlight();
        }
    });
});

document.addEventListener('keydown', keyDownHandler);
