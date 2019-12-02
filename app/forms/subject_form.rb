class SubjectForm
  include ActiveModel::Model

  attr_accessor :class_map
  attr_accessor :uri, :rdf_types, :label, :language, :condition
  
  def update!
    uri.save!

    rdf_types.each(&:save!)

    label.save!
    language.save!
    #self.condition.save!
  end

  def initialize_by_class_map
    self.rdf_types = []

    class_map.class_map_property_settings.each do |cmps|
      if cmps.subject?
        self.uri = cmps
      elsif cmps.rdf_type?
        rdf_types << cmps
      elsif cmps.condition?
        self.condition = cmps
      end
    end

    label_pb = class_map.property_bridge_for_resource_label
    if label_pb
      self.label = PropertyBridgePropertySetting.find_by(
          property_bridge_id: label_pb.id,
          property_bridge_property_id: PropertyBridgeProperty.literal_pattern.id
      )
      self.language = PropertyBridgePropertySetting.find_by(
          property_bridge_id: label_pb.id,
          property_bridge_property_id: PropertyBridgeProperty.lang.id
      )
    else
      include TogoMapper::Mapping

      label_hash = create_models_for_resource_label(class_map)
      self.label = label_hash[:object]
      self.language = label_hash[:lang]
    end
  end
end
