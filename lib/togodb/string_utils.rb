module Togodb::StringUtils

  def replace_colname_to_value(tmpl, record, columns)
    uri = tmpl.clone
    replace_columns = tmpl.scan(/\{.+?\}/)
    if replace_columns.kind_of?(Array)
      replace_columns.uniq.each do |replace_column|
        col_name = replace_column[1 .. -2]
        idx = columns.index{ |item| item.name == col_name }
        next if idx.nil?

        internal_column_name = columns[idx].internal_name
        col_value = record[internal_column_name].to_s
        uri = uri.to_s.gsub(/#{Regexp.escape(replace_column)}/, col_value)
      end
    end

    uri
  end

  def multibyte_truncate(text, length = 30, truncate_string = '...')
    array = text.to_s.split(//)
    return text if array.size <= length

    size = [0, length-1].max
    text = array[0, size].join
    text + truncate_string
  end

  def random_str(length = 32)
    source = ('a'..'z').to_a + ('A'..'Z').to_a + (0..9).to_a + ['_']
    key = ''
    length.times { key += source[rand(source.size)].to_s }

    key
  end

end
