class ClassMapPropertySetting < PropertySetting

  belongs_to :class_map
  belongs_to :class_map_property

  before_save :to_relative_uri

  delegate :property, to: :class_map_property, allow_nil: true

  def base_uri
    class_map.work.base_uri
  end

  def uri_pattern?
    class_map_property_id == ClassMapProperty.uri_pattern.id
  end

  def uri_column?
    class_map_property_id == ClassMapProperty.uri_column.id
  end

  def subject?
    resource_identity_class_map_property_ids = ClassMapProperty.for_resource_identity.map(&:id)
    resource_identity_class_map_property_ids << ClassMapProperty.bnode.id
    resource_identity_class_map_property_ids.include?(class_map_property_id)
  end

  def rdf_type?
    class_map_property_id == ClassMapProperty.rdf_type.id
  end

  def condition?
    class_map_property_id == ClassMapProperty.condition.id
  end

  def form_id(target_field = 'value')
    "cmps_#{self.id}_#{target_field}"
  end

  def form_name(target_field = 'value')
    form_name_keys = []

    form_name_keys << id
    form_name_keys << target_field

    "class_map_property_setting#{form_name_keys.map { |key| "[#{key}]" }.join}"
  end

end
