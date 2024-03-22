$ ->
    $(".id-separator-selector").change ->
        column_id = $(this).data "colid"
        selected = $("##{$(this).attr("id")} option:selected").val()
        $("#togodb_column_#{column_id}_id_separator").val selected

    $(".id-separator-text").keyup ->
        column_id = $(this).data "colid"
        id_separator_text = $(this).val()
        blank = $("#togodb_column_#{column_id}_id_separator_pdl option[value='']")
        target = $("#togodb_column_#{column_id}_id_separator_pdl option[value='" + id_separator_text + "']")
        if target.length is 1
            target.prop("selected", true)
        else
            blank.prop("selected", true)

    $(".link-other-type-selector").change ->
        column_id = $(this).data "colid"
        column_name = $(this).data "colname"
        selected = $("##{$(this).attr("id")} option:selected").val()
        link_text_field_id = "togodb_column_#{column_id}_html_link_prefix"
        if selected is ""
            $("##{link_text_field_id}").val ""
        else
            $("##{link_text_field_id}").val html_link[selected].replace("{id}", "{#{column_name}}")

    $(".html-link-text").keyup ->
        column_id = $(this).data "colid"
        column_name = $(this).data "colname"
        text_field_value = $(this).val()
        compared_text = text_field_value.replace "{#{column_name}}", "{id}"
        blank = $("#togodb_column_#{column_id}_other_type option[value='']")

        other_types = Object.keys(html_link)
        for other_type in other_types
            if compared_text is html_link[other_type]
                select_option = $("#togodb_column_#{column_id}_other_type option[value='" + other_type + "']")
                select_option.prop "selected", true
                break
            blank.prop "selected", true
