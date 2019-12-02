// code
// table_code
function editManager(prefix) {
    var tabManager = new TabManager();

    var tabCodeBody = new Tab(prefix + "_body",tabManager);
    var tabCodeHeader = new Tab(prefix + "_header",tabManager);
    var tabCodeCss = new Tab(prefix + "_css",tabManager);
    var tabColumnsSettings = new Tab(prefix + "_columns_settings",tabManager);
    var tabColumnsLinks = new Tab(prefix + "_columns_link",tabManager);

    var editors = {};

    tabManager.addTab(tabCodeBody);
    tabManager.addTab(tabCodeHeader);
    tabManager.addTab(tabCodeCss);
    tabManager.addTab(tabColumnsSettings);
    tabManager.addTab(tabColumnsLinks);
    
    // Define an extended mixed-mode that understands vbscript and
    // leaves mustache/handlebars embedded templates in html mode
    var mixedMode = {
	name: "htmlmixed",
	lineNumbers: true,
	scriptTypes: [{matches: /\/x-handlebars-template|\/x-mustache/i,
	               mode: null},
	              {matches: /(text|application)\/(x-)?vb(a|script)/i,
	               mode: "vbscript"}]
    };

    $('#' + prefix + '_header_contents').hide(1);
    $('#' + prefix + '_css_contents').hide(1);

    editors['css'] = CodeMirror.fromTextArea(document.getElementById(prefix + "_textarea_css"), {
	mode: "text/css",
	lineNumbers:true,
	selectionPointer: true
    });
    
    var delay;
    editors['css'].on("change", function() {
	clearTimeout(delay);
	delay = setTimeout(updatePreview, 300);
    });

    /*
    function updatePreview() {
        var previewFrame = document.getElementById(prefix + '_preview');
        var preview = previewFrame.contentDocument || previewFrame.contentWindow.document;
        preview.open();
        var headerTxt = '<head>' + editors['header'].getValue() + '<style>' + editors['css'].getValue() + '</style>' + '</head>';
        var bodyTxt = '<body>' + editors['body'].getValue() + '</body>';
        var htmlTxt = '<html>' + headerTxt + bodyTxt + '</html>';
        preview.write(htmlTxt);
        preview.close();
    }
    */
    function updatePreview() {

    }
    
    setTimeout(updatePreview, 300);
    
    editors['header'] = CodeMirror.fromTextArea(document.getElementById(prefix + "_textarea_header"), {
	mode: mixedMode,
	lineNumbers: true,
	selectionPointer: true
    });
    
    editors['header'].on("change", function() {
	clearTimeout(delay);
	delay = setTimeout(updatePreview, 300);
    });
    
    editors['body'] = CodeMirror.fromTextArea(document.getElementById(prefix + "_textarea_body"), {
	mode: mixedMode,
	lineNumbers: true,
	selectionPointer: true
    });
    
    editors['body'].on("change", function() {
	clearTimeout(delay);
	delay = setTimeout(updatePreview, 300);
    });

    return editors;
}

$(function() {
    editors = {}
    editors['entry'] = editManager('entry_code');
    editors['table'] = editManager('table_code');
      
      // entry_edit
      //

      var tabManagerPrview = new TabManager();
      
      var tabEntry = new Tab("entry_edit",tabManagerPrview);
      var tabTable = new Tab("table_edit",tabManagerPrview);
      tabEntry.$other_content = $('#entry_code_preview');
      tabTable.$other_content = $('#table_code_preview');
      
      tabManagerPrview.addTab(tabEntry);
      tabManagerPrview.addTab(tabTable);		 

      $('#table_edit_contents').hide(1);
      tabTable.$other_content.hide(1);
});

/*
$("#togodb_create_column_type_select_3799").change(function() {
    var selected_type = $("#togodb_create_column_type_select_3799 option:selected").val();
    var num_decimal_place_elem = $("#togodb_create_column_3799_num_decimal_places");
    if (selected_type == "decimal") {
	num_decimal_place_elem.show();
    } else {
	num_decimal_place_elem.hide();
    }
});

$("#togodb_create_column_type_select_3800").change(function() {
    var selected_type = $("#togodb_create_column_type_select_3800 option:selected").val();
    var num_decimal_place_elem = $("#togodb_create_column_3800_num_decimal_places");
    if (selected_type == "decimal") {
	num_decimal_place_elem.show();
    } else {
	num_decimal_place_elem.hide();
    }
});

$("#togodb_create_column_type_select_3801").change(function() {
    var selected_type = $("#togodb_create_column_type_select_3801 option:selected").val();
    var num_decimal_place_elem = $("#togodb_create_column_3801_num_decimal_places");
    if (selected_type == "decimal") {
	num_decimal_place_elem.show();
    } else {
	num_decimal_place_elem.hide();
    }
});

$("#togodb_create_column_type_select_3802").change(function() {
    var selected_type = $("#togodb_create_column_type_select_3802 option:selected").val();
    var num_decimal_place_elem = $("#togodb_create_column_3802_num_decimal_places");
    if (selected_type == "decimal") {
	num_decimal_place_elem.show();
    } else {
	num_decimal_place_elem.hide();
    }
});

$("#togodb_create_column_type_select_3803").change(function() {
    var selected_type = $("#togodb_create_column_type_select_3803 option:selected").val();
    var num_decimal_place_elem = $("#togodb_create_column_3803_num_decimal_places");
    if (selected_type == "decimal") {
	num_decimal_place_elem.show();
    } else {
	num_decimal_place_elem.hide();
    }
});

$("#togodb_create_column_type_select_3804").change(function() {
    var selected_type = $("#togodb_create_column_type_select_3804 option:selected").val();
    var num_decimal_place_elem = $("#togodb_create_column_3804_num_decimal_places");
    if (selected_type == "decimal") {
	num_decimal_place_elem.show();
    } else {
	num_decimal_place_elem.hide();
    }
});
*/
