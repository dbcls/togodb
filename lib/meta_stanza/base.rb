# frozen_string_literal: true
require 'erb'

module MetaStanza
  class Base
    include ERB::Util

    def initialize(togodb_table, html_escape: true, debug_mode: false)
      @togodb_table = togodb_table
      @html_escape = html_escape
      @debug_mode = debug_mode

      @tag_lines = nil
      @attributes = []
    end

    def tag_lines
      @tag_lines = generate_html_tag if @tag_lines.nil?

      @tag_lines
    end

    def html_tag
      tag_lines.join("\n")
    end

    def attribute_line(attribute)
      if attribute[0] == 'columns' && !@html_escape
        %(  #{attribute[0]}='#{attribute[1]}')
      else
        %(  #{attribute[0]}="#{attribute[1]}")
      end
    end

    private

    def generate_html_tag
      @tag_lines = []

      add_attributes

      @tag_lines << "<#{tag_name}"
      @attributes.each do |attr|
        @tag_lines << attribute_line(attr)
      end
      @tag_lines << "></#{tag_name}>"
    end

    def add_attribute(name, value)
      @attributes << [name, value]
    end

    def url_scheme
      Togodb.url_scheme
    end

    def api_server
      Togodb.api_server
    end

    def add_attributes; end
    def tag_name; end
  end
end
