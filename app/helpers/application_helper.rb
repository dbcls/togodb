module ApplicationHelper

  def nl2br(str)
    str.gsub(/\r\n|\r|\n/, '<br />')
  end

  def format_float(value, column)
    if value.nil?
      value = ''
    else
      if column.num_decimal_places.blank?
        value_s = value.to_s
        if value == 0
          value = value_s
        elsif value_s.downcase.include?('e')
          value = value_s
        elsif value.abs < 0.00001
          /([1-9]+)\z/ =~ value_s
          if $1 && $1.size > 1
            p = $1.size - 1
          else
            p = 0
          end
          value = "%.#{p}e" % value
        elsif value.abs > 1000000
          /\A\-?([0-9]+)\.?([0-9]*)\z/ =~ value_s
          if $1 && $1.size > 0
            p = $1.size
          else
            p = 0
          end
          if $2 && $2 != '0' && $2.size > 0
            p += $2.size
          end
          if p > 0
            p -= 1
          end
          value = "%.#{p}e" % value
        else
          value = value_s
        end
      else
        value = sprintf("%.#{column.num_decimal_places}f", value)
      end
    end

    value
  end

  def convert_url_link(str)
    begin
      unless str.blank?
        if str.to_s =~ /(https?:\/\/[\w\-\.\!\~\*\(\)\;\/\?\:\@\&\=\+\$\,\%\#]+)/
          %Q(<a href="#{$1}" target="_blank">#{$1}</a>)
        else
          str
        end
        #str.to_s.gsub(/(https?:\/\/[\w\-\.\!\~\*\(\)\;\/\?\:\@\&\=\+\$\,\%\#]+)/) {
        #  '<a href="' + $1 + '" target="_blank">' + $1 + '</a>'
        #}
      end
    rescue => e
      str
    end
  end

  def checkbox_tag_with_hidden(name, checked_value='1', unchecked_value='0', checked=false, options = {})
    html = %Q(<input type="hidden" name="#{name}" value="#{unchecked_value}" />)
    html << check_box_tag(name, checked_value, checked, options)

    html
  end

  def advanced_search_input_elem_name(column)
    "search[#{column.internal_name}]"
  end

  def advanced_search_text_form_element(column, search_params, value = nil)
    text_field_tag(advanced_search_input_elem_name(column), value,
                   { autocomplete: 'off',  size: 30, class: 'bgWhite', id: "search_#{column.internal_name}" })
  end

  def advanced_search_form_element(column, search_params, value = nil)
    name = advanced_search_input_elem_name(column)

    if column.has_data_type?
      advanced_search_text_form_element(column, search_params, value)
    else
      case column.data_type
      when 'integer', 'bigint', 'float', 'decimal'
        text_field_size = column.data_type == 'bigint' ? 20 : 10
        if value.kind_of?(Hash)
          from = value['from']
          to = value['to']
        else
          from = ''
          to = ''
        end
        'from ' +
            text_field_tag(name+'[from]', from, { size: text_field_size, class: 'bgWhite' }) +
            ' to ' +
            text_field_tag(name+'[to]', to, { size: text_field_size, class: 'bgWhite' })
      when 'date'
        if value.kind_of?(Hash)
          if value['from'].kind_of?(Hash)
            from_year = value['from']['year']
            from_month = value['from']['month']
            from_day = value['from']['day']
          else
            from_year = ''
            from_month = ''
            from_day = ''
          end

          if value['to'].kind_of?(Hash)
            to_year = value['to']['year']
            to_month = value['to']['month']
            to_day = value['to']['day']
          else
            to_year = ''
            to_month = ''
            to_day = ''
          end
        else
          from_year = ''
          from_month = ''
          from_day = ''
          to_year = ''
          to_month = ''
          to_day = ''
        end
        'from ' +
            text_field_tag(name+'[from][year]', from_year, { size: 4, class: 'bgWhite' }) +
            text_field_tag(name+'[from][month]', from_month, { size: 2, class: 'bgWhite' }) +
            text_field_tag(name+'[from][day]', from_day, { size: 2, class: 'bgWhite' }) +
            ' to ' +
            text_field_tag(name+'[to][year]', to_year, { size: 4, class: 'bgWhite' }) +
            text_field_tag(name+'[to][month]', to_month, { size: 2, class: 'bgWhite' }) +
            text_field_tag(name+'[to][day]', to_day, { size: 2, class: 'bgWhite' })
      when 'time'
        if value.kind_of?(Hash)
          if value['from'].kind_of?(Hash)
            from_hour = value['from']['hour']
            from_min = value['from']['min']
            from_sec = value['from']['sec']
          else
            to_year = ''
            to_month = ''
            to_day = ''
          end

          if value['to'].kind_of?(Hash)
            to_hour = value['to']['hour']
            to_min = value['to']['min']
            to_sec = value['to']['sec']
          else
            to_hour = ''
            to_min = ''
            to_sec = ''
          end
        else
          from_hour = ''
          from_min = ''
          from_sec = ''
          to_hour = ''
          to_min = ''
          to_sec = ''
        end
        'from ' +
            text_field_tag(name+'[from][hour]', from_hour, { size: 2, class: 'bgWhite' }) +
            text_field_tag(name+'[from][min]', from_min, { size: 2, class: 'bgWhite' }) +
            text_field_tag(name+'[from][sec]', from_sec, { size: 2, class: 'bgWhite' }) +
            ' to ' +
            text_field_tag(name+'[to][hour]', to_hour, { size: 2, class: 'bgWhite' }) +
            text_field_tag(name+'[to][min]', to_min, { size: 2, class: 'bgWhite' }) +
            text_field_tag(name+'[to][sec]', to_sec, { size: 2, class: 'bgWhite' })
      when 'boolean'
        options = [['', ''],
                   ['True', '1'],
                   ['False', '0']
        ]
        select_tag name, options_for_select(options, value)
      when 'string'
        if column.other_type == 'list'
          list_column_values_select_tag(column, value)
        else
          advanced_search_text_form_element(column, search_params, value)
        end
      else
        advanced_search_text_form_element(column, search_params, value)
      end
    end
  end

  def list_column_values_select_tag(column, value = nil)
    values = TogodbColumnValue.where(column_id: column.id).order('value')

    select_tag "search[#{column.internal_name}]",
               options_from_collection_for_select(values, :value, :value, value),
               include_blank: true
  end

end
