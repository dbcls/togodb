# frozen_string_literal: true

module MetaStanza
  class PaginationTable < MetaStanza::Base
    include MetaStanza::MixIn

    class << self
      def metastanza_javascript_url
        # 'https://togostanza.github.io/metastanza-devel/pagination-table.js'
        '/metastanza-devel/pagination-table.js'
      end
    end

    def tag_name
      'togostanza-pagination-table'
    end

    def data_url
      "#{url_scheme}://#{api_server}/db/#{@togodb_table.name}.json"
    end

    def add_attributes
      add_attribute('data-url', data_url)
      add_attribute('data-type', 'json')
      add_attribute('page-size-option', '10,20,50,100')
      add_attribute('columns', @html_escape ? html_escape(columns_attr_value) : columns_attr_value)
    end

    def columns_attr_value
      column_attrs = [
        {
          id: MetaStanza::ENTRY_COLUMN_NAME,
          label: 'Entry',
          link: metastanza_column_link_attr_key(MetaStanza::ENTRY_COLUMN_NAME),
          target: '_blank'
        }
      ]

      @togodb_table.columns.where(enabled: true).each do |togodb_column|
        column_attrs << hash_for_columns_attr(togodb_column)
      end

      if @debug_mode
        require 'json'
        puts '--- column_attr'
        puts column_attrs if @debug_mode
        puts '--- JSON'
        puts column_attrs.to_json
        puts '--- JSON.parse'
        puts JSON.parse(column_attrs.to_json)
      end

      column_attrs.to_json
    end
  end
end
