# frozen_string_literal: true

module MetaStanza
  module MixIn
    def hash_for_columns_attr(togodb_column)
      hash = {
        id: togodb_column.name,
        label: togodb_column.label
      }

      hash[:escape] = false unless togodb_column.sanitize?
      if togodb_column.has_link?
        hash[:link] = metastanza_column_link_attr_key(togodb_column.name)
        hash[:target] = '_blank'
      end

      hash
    end

    def metastanza_column_link_attr_key(column_name)
      [LINK_FIELD_KEY_PREFIX, column_name].join
    end
  end
end
