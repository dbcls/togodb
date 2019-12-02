class PropertyBridgeProperty < ApplicationRecord

  default_scope { order(id: :asc) }

  scope :by_property, ->(property) {
    where(property: "d2rq:#{property}").first
  }

  scope :subject_property, -> { find_by(property: 'd2rq:belongsToClassMap') }

  scope :predicate_properties, -> { where(property: %w[d2rq:property d2rq:dynamicProperty]) }

  scope :uri_object_properties, -> { where(property: %w[d2rq:uriColumn d2rq:uriPattern]) }

  scope :optional_properties, -> { where.not(property: %w[d2rq:belongsToClassMap d2rq:property d2rq:dynamicProperty d2rq:column d2rq:pattern d2rq:sqlExpression d2rq:uriColumn d2rq:uriPattern d2rq:uriSqlExpression d2rq:constantValue d2rq:refersToClassMap d2rq:lang d2rq:datatype]).reorder('UPPER(label)') }

  scope :property, -> { where(property: 'd2rq:property').first }

  scope :refers_to_class_map, -> { find_by(property: 'd2rq:refersToClassMap') }

  scope :lang, -> { find_by(property: 'd2rq:lang') }
  scope :datatype, -> { find_by(property: 'd2rq:datatype') }
  scope :condition, -> { find_by(property: 'd2rq:condition') }

  scope :predicate_default, -> { find_by(property: 'd2rq:property') }
  scope :object_default, -> { find_by(property: 'd2rq:column') }

  scope :uri_pattern, -> { find_by(property: 'd2rq:uriPattern') }
  scope :uri_column, -> { find_by(property: 'd2rq:uriColumn') }
  scope :literal_pattern, -> { find_by(property: 'd2rq:pattern') }
  scope :literal_column, -> { find_by(property: 'd2rq:column') }

  has_many :property_bridge_property_settings

  class << self

    def subject_format_properties
      [uri_pattern, uri_column]
    end

    def object_properties
      [uri_pattern, uri_column, literal_pattern, literal_column]
    end

    def join_object_properties
      where(property: 'd2rq:refersToClassMap') + where(property: %w[d2rq:column d2rq:pattern d2rq:uriColumn d2rq:uriPattern]).order(:id)
    end

  end

end
