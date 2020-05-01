module TablesHelper
  include Togodb::Link
  include Togodb::StringUtils

  def html_value(record, column)
    begin
      if @all_data
        all_data = @all_data
      else
        all_data = @table.active_record.find(record.id)
      end
    rescue
      all_data = record
    end
    value = all_data[column.internal_name]

    if column.data_type == 'datetime'
      value = value.to_s.split(/ /)[0 .. 1].join(' ')
    end

    if column.data_type == 'float' || column.data_type == 'decimal'
      value = format_float(value, column)
    end

    value = convert_url_link(ERB::Util.html_escape(value)) if column.sanitize

    if column.has_link?
      case controller_name
      when 'tables'
        value = add_html_link(all_data, column, value)
      when 'entries'
        if column.html_link_prefix.start_with?('http') || value.to_s =~ /\A<[A-Za-z]+/
          value = add_html_link(all_data, column, value)
        end
      end
    end

    if !value.nil? && column.sequence_type?
      value = if /(\r|\n)/ =~ value
                nl2br(value)
              else
                value.scan(/.{1,60}/).join('<br />')
              end
      value = "<tt>#{value}</tt>"
    else
      value = nl2br(value.to_s)
    end

    if value.nil? || value.to_s == ''
      '-'
    else
      value
    end
  end

  def add_html_link(record, column, value)
    if column.html_link_prefix.blank? && column.html_link_suffix.blank?
      if column.other_type.blank? || column.other_type == 'sequence' || column.other_type == 'list'
        value
      else
        add_xref_link(record, column, value)
      end
    else
      html_link_prefix = ''
      unless column.html_link_prefix.blank?
        html_link_prefix = replace_html_link_column_value(record, column)
      end

      html_link_suffix = if column.html_link_suffix.blank?
                           # Link prefix starts with HTML tag and has not end tag
                           if column.html_link_prefix.strip =~ /\A<([a-zA-Z]+)\s+[^<>]*>\z/
                             "</#{$1}>"
                           else
                             ''
                           end
                         else
                           suffix = column.html_link_suffix.strip
                           if html_link_prefix[suffix.size * -1 .. -1] == suffix
                             ''
                           elsif suffix =~ /\A<\/[A-Za-z]+\s*>\z/
                             suffix
                           else
                             replace_html_link_column_value(record, column)
                           end
                         end

      if html_link_suffix.blank?
        html_link_prefix
      else
        html_link_prefix.to_s + value.to_s + html_link_suffix.to_s
      end
    end
  end

  def replace_html_link_column_value(record, column)
    link = column.html_link_prefix
    return '' if link.blank?

    value = record[column.internal_name]
    return '' if value.blank?

    unless column.id_separator.blank?
      return value_by_id_separator(record, column, link)
    end

    if column.xref?
      id_regexp = id_pattern_regexp(column)
      unless id_regexp.nil?
        link = value.to_s.gsub(id_regexp) do |v|
          href = link.to_s.gsub("{#{column.name}}", v)
          if /\A<([A-Za-z]+)/ =~ href
            href
          else
            %(<a href="#{href}" target="_blank">#{v}</a>)
          end
        end
      end
    end

    @table = TogodbTable.find(column.table_id) unless @table
    togodb_columns = @togodb_columns || @table.columns
    link = replace_colname_to_value(link, record, togodb_columns)

    if link[0, 2].to_s.downcase != '<a' && link[0, 4].to_s.downcase != '<img'
      link = %(<a href="#{link}" target="_blank">#{value}</a>)
    end

    link
  end

  def quickbrowse_data_elem_id(name)
    "togodb-quickbrowse-#{name}"
  end

  def content_for_opensearch(query, record, columns)
    query = query[1 .. -2] if query[0, 1] == '"' and query[-1, 1] == '"'

    values = []
    columns.each do |column|
      v = record[column.internal_name]
      values << v.to_s unless v.blank?
    end

    s = values.join(',')
    pos = s.index(query)
    if pos.nil?
      s
    else
      start_pos = pos > 100 ? pos - 100 : 0
      end_pos = pos + query.size + 100
      s[start_pos .. end_pos]
    end
  end

  def search_example
    columns = @table.simple_search_columns
    record = @table.active_record.first
    v = record[columns[0].internal_name]
    pos = v.index(/\s/)
    if pos
      v[0 .. pos - 1]
    else
      v
    end
  end

  def apply_column_tmpl(record, column, link_tmpl, column_value, add_atag = true)
    togodb_columns = @togodb_columns || @table.columns

    r = if record.is_a?(ActiveRecord)
          record.attributes
        else
          record.dup
        end
    r[column.internal_name] = column_value
    if add_atag
      %(<a href="#{replace_colname_to_value(link_tmpl, r, togodb_columns)}" target="_blank">#{column_value}</a>)
    else
      replace_colname_to_value(link_tmpl, r, togodb_columns).to_s
    end
  end

  def value_by_id_separator(record, column, link_tmpl, add_atag = true)
    values = []

    id_separator = column.id_separator.to_s.strip
    if id_separator != '/' && id_separator[0, 1] == '/' && id_separator[-1, 1] == '/'
      id_separator = Regexp.compile(id_separator[1 .. -2].gsub("¥", "\\"))
    else
      id_separator = Regexp.compile(Regexp.escape id_separator)
    end

    column_value = record[column.internal_name].to_s
    while id_separator =~ column_value
      values << apply_column_tmpl(record, column, link_tmpl, $`, add_atag)
      values << $&

      column_value = $'
    end
    values << apply_column_tmpl(record, column, link_tmpl, column_value, add_atag) unless column_value.nil?

    values.join
=begin
    actual_separator = actual_separator(record[column.internal_name].to_s, column.id_separator)
    split_by_separator(record[column.internal_name].to_s, column.id_separator).each do |v|
      r = if record.is_a?(ActiveRecord)
            record.attributes
          else
            record.dup
          end
      r[column.internal_name] = v
      if add_atag
        values << %(<a href="#{replace_colname_to_value(link_tmpl, r, @table.columns)}" target="_blank">#{v}</a>)
      else
        values << replace_colname_to_value(link_tmpl, r, @table.columns).to_s
      end
    end

    if values.empty?
      ''
    else
      values.join(actual_separator)
    end
=end
  end

  def split_by_separator(text, separator)
    regexp_separator = '[\n\r]*' + Regexp.escape(separator) + '[\n\r]*'

    text.split(/#{regexp_separator}/)
  end

  def actual_separator(text, separator)
    split = split_by_separator(text, separator)
    actual = ''
    if 1 < split.length
      split_2 = text.slice(split[0].length, text.length)
      actual = split_2.slice(0, split_2.index(split[1]))
    end

    actual
  end

  def flexigrid_params
    fg_params = [{ name: 'preview', value: @preview }]
    if params[:togodb_view_page_key]
      fg_params << { name: 'togodb_view_page_key', value: params[:togodb_view_page_key].to_s }
    end

    fg_params
  end

  def flexigrid_properties(jsonize = true)
    sorting_column = @table.default_sorting_column
    props = {
      url: flexigrid_fetch_url(@table),
      params: flexigrid_params,
      method: 'get',
      dataType: 'json',
      sortname: sorting_column.nil? ? '' : sorting_column.internal_name,
      sortorder: 'asc',
      usepager: true,
      title: @table.name,
      rp: 15,
      rpOptions: [15, 30, 50, 100],
      showTableToggleBtn: true,
      width: @width,
      height: @height,
      is_released_data: @released_datasets.empty? ? 'false' : 'true',
      dbname: @table.name,
      dbid: @table.id,
      ck: "#{@table.name}-#{@table.id}"
    }

    props[:colModel] = [
      {
        column_id: 0,
        label: 'Entry',
        name: '_SHOW_LINK',
        width: 40,
        sortable: false,
        align: 'left',
        hide: false
      }
    ]
    @view_show_merged_columns.each do |column|
      text_align = column.number? ? 'right' : 'left'
      col_model = {
        column_id: column.id,
        label: column.label,
        name: column.internal_name,
        oname: column.name,
        width: @column_width[column.internal_name],
        sortable: !@table.disable_sort,
        align: text_align,
        hide: column.list_disp_order.blank?
      }
      col_model[:comment] = column.comment unless column.comment.blank?
      props[:colModel] << col_model
    end

    props[:searchitems] = [
      { label: 'All', name: 'ALL' }
    ]
    @search_columns.each do |column|
      props[:searchitems] << { label: column.label, name: column.id }
    end

    props[:onSuccess] = render partial: 'flexigrid_onsuccess'

    if @buttons
      props[:buttons] = []
      if @writable
        props[:buttons] << { separator: true }
        props[:buttons] << { name: 'Add', bclass: 'add', onpress: 'add_pressed();' }
        props[:buttons] << { separator: true }
        props[:buttons] << { name: 'Edit', bclass: 'edit', onpress: 'edit_pressed();' }
        props[:buttons] << { separator: true }
        props[:buttons] << { name: 'Delete', bclass: 'delete', onpress: 'delete_pressed();' }
      end
    end

    if jsonize
      require 'json'
      JSON.generate(props)
    else
      props
    end
  end

end
