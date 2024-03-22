# frozen_string_literal: true

module MetaStanza
  class KeyValue < MetaStanza::Base
    include MetaStanza::MixIn

    class << self
      def metastanza_javascript_url
        # 'https://togostanza.github.io/metastanza-devel/key-value.js'
        '/metastanza-devel/key-value.js'
      end
    end

    def initialize(togodb_table, html_escape: nil, debug_mode: nil)
      super

      @togodb_columns = @togodb_table.columns_for_entry
    end

    def tag_name
      'togostanza-key-value'
    end

    def data_url
      "#{url_scheme}://#{api_server}/entry/#{@togodb_table.name}.json"
    end

    def add_attributes
      add_attribute('data-url', data_url)
      add_attribute('data-type', 'json')
      add_attribute('columns', @html_escape ? html_escape(columns_attr_value) : columns_attr_values)
      add_attribute('togostanza-custom_css_url', custom_css_url)
    end

    def columns_attr_values
      @togodb_columns.map { |column| hash_for_columns_attr(column) }.to_json
    end

    def custom_css_url
      ''
    end
  end
end
