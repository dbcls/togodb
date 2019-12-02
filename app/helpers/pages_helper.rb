module PagesHelper

  def view_table_id(dbname)
    "togodb-#{dbname}"
  end

  def link_html_tmpl_for_entry(column)
    link = column.html_link_prefix
    replace_columns = link.scan(/\{.+?\}/)
    if replace_columns.is_a?(Array)
      replace_columns.uniq.each do |replace_column|
        col_name = replace_column[1 .. -2]
        if col_name == column.name
          internal_column_name = column.internal_name
        else
          c = TogodbColumn.find_by(name: col_name, table_id: column.table_id)
          next if c.nil?
          internal_column_name = c.internal_name
        end
        link = link.to_s.gsub(/#{Regexp.escape("{#{col_name}}")}/, "{{#{col_name}_value}}")
      end
    end

    tmpl = if link =~ /\A<([A-Za-z]+)/
             tag_name = $1.dup
             if link.strip =~ /<\/#{tag_name}\s*>\z/i
               link
             else
               "#{link}{{#{column.name}_value}}</#{tag_name}>"
             end
           else
             %(<a href="#{link}" target="_blank">{{#{column.name}_value}}</a>)
           end

    tmpl
  end

  def html_setting_default_link(label, action, table_id, elem_id, elem_class)
    link_to label, eval("#{action}_togodb_page_path(@page)"),
            remote: true, data: { confirm: 'Are you sure ?' },
            id: elem_id, class: "#{elem_class} togodb-config-default-submit"
  end

  def html_setting_update_button(button_label, elem_class)
    submit_tag button_label, class: elem_class
  end

  def html_setting_update_default_buttons(update_label, default_label, action, table_id, elem_id, elem_class)
    html_setting_update_button(update_label, elem_class) +
      html_setting_default_link(default_label, action, table_id, elem_id, elem_class)
  end

end
