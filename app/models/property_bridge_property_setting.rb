class PropertyBridgePropertySetting < PropertySetting

  belongs_to :property_bridge
  belongs_to :property_bridge_property

  delegate :property, to: :property_bridge_property

  before_save :to_relative_uri

  class << self

    def for_subject(property_bridge_id)
      subject_pb = PropertyBridgeProperty.subject_property
      PropertyBridgePropertySetting.find_by(property_bridge_id: property_bridge_id, property_bridge_property_id: subject_pb.id)
    end

    def for_predicate(property_bridge_id)
      predicate_pbs = PropertyBridgeProperty.predicate_properties
      PropertyBridgePropertySetting.find_by(property_bridge_id: property_bridge_id, property_bridge_property_id: predicate_pbs.map(&:id))
    end

    def for_object(property_bridge_id)
      object_pbs = PropertyBridgeProperty.object_properties
      PropertyBridgePropertySetting.find_by(property_bridge_id: property_bridge_id, property_bridge_property_id: object_pbs.map(&:id))
    end

    def for_optional(property_bridge_id)
      other_pbs = PropertyBridgeProperty.optional_properties
      PropertyBridgePropertySetting.where(property_bridge_id: property_bridge_id, property_bridge_property_id: other_pbs.map(&:id))
    end

    def for_lang(property_bridge_id)
      lang_property = PropertyBridgeProperty.lang
      PropertyBridgePropertySetting.find_by(property_bridge_id: property_bridge_id, property_bridge_property_id: lang_property.id)
    end

    def for_datatype(property_bridge_id)
      datatype_property = PropertyBridgeProperty.datatype
      PropertyBridgePropertySetting.find_by(property_bridge_id: property_bridge_id, property_bridge_property_id: datatype_property.id)
    end

    def form_name(pb_id, pbps_id, target_field = 'value')
      name_keys = [pb_id]
      name_keys << pbps_id
      name_keys << target_field

      "property_bridge#{name_keys.map{ |key| "[#{key}]" }.join}"
    end
  end


  def predicate?
    PropertyBridgeProperty.predicate_properties.map(&:id).include?(property_bridge_property_id)
  end

  def uri_pattern?
    property_bridge_property_id == PropertyBridgeProperty.uri_pattern.id
  end

  def uri_object?
    PropertyBridgeProperty.uri_object_properties.map(&:id).include?(property_bridge_property_id)
  end

  def property_value?
    PropertyBridgeProperty.object_properties.map(&:id).include?(property_bridge_property_id)
  end

  def language?
    property_bridge_property_id == PropertyBridgeProperty.lang.id
  end

  def datatype?
    property_bridge_property_id == PropertyBridgeProperty.datatype.id
  end

  def condition?
    property_bridge_property_id == PropertyBridgeProperty.condition.id
  end

  def base_uri
    property_bridge.work.base_uri
  end

  def form_id(target_field = 'value')
    "pbps_#{id}_#{target_field}"
  end

  def form_name(target_field = 'value')
    PropertyBridgePropertySetting.form_name(property_bridge_id, id, target_field)
  end

end
