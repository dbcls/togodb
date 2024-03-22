class TogodbGraph < ApplicationRecord
  belongs_to :togodb_column

  def api_url
    togodb_table = TogodbTable.find(togodb_column.table_id)
    url = [Togodb.api_server, 'chart', chart_type, togodb_table.name, togodb_column.name].join('/')

    "#{Togodb.url_scheme}://#{url}.json"
  end

  def metastanza_help_query_string
    tag_attr_lines = embed_tag.split(/\n/).reject { |line| line.include?('togostanza') }
    query_params = tag_attr_lines.map do |line|
      name, value = line.strip.split(/\s*=\s*/)
      if value.nil?
        [name, true]
      else
        [name, value[1..-2]]
      end
    end

    unless query_params.map(&:first).include?('legend-visible')
      query_params << ['legend-visible', false]
    end

    query_params.unshift(['data-url', api_url]);

    URI.encode_www_form(query_params)
  end
end
