class PropertySetForm
  include ActiveModel::Model

  attr_accessor :property_bridge
  attr_accessor :predicates
  attr_accessor :object_value, :object_language, :object_datatype, :object_condition


  def initialize_by_property_bridge
    property_bridge = self.property_bridge

    self.predicates = property_bridge.predicate

    object = property_bridge.object.first
    self.object_value = object

    self.object_language = property_bridge.pbps_for_lang
    self.object_datatype = property_bridge.pbps_for_datatype
    self.object_condition = property_bridge.pbps_for_condition
  end

  def update!
    property_bridge.save!

    predicates.each(&:save!)

    object_value.save!
    object_language.save!
    object_datatype.save!
    #self.object_condition.save!
  end

  def object_form_value
    object_value.property_bridge_property_id
  end

  def object_format_d2rq_property
    object_value.property_bridge_property.property
  end

  def enable?
    property_bridge.enable
  end

  def enable_form_name
    "property_bridge[#{property_bridge.id}][enable]"
  end

  def enable_form_id
    "column-rdf-enable-#{property_bridge.id}"
  end
end
