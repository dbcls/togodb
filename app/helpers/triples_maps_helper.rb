module TriplesMapsHelper

  def column_rdf_button_class(property_bridge)
    if property_bridge && property_bridge.enable
      'btn btn-primary btn-rdf btn-rdf-disable'
    else
      'btn btn-default btn-rdf btn-rdf-enable'
    end
  end

  def new_pb_instance
    PropertyBridge.create!(
        work_id: @property_bridge.work_id,
        class_map_id: @class_map.id,
        column_name: @property_bridge.column_name,
        enable: true,
        property_bridge_type_id: @property_bridge.property_bridge_type_id
    )
  end

  def new_pbps_hash(property_bridge)
    # PropertyBridgePropertySetting for d2rq:belongsToClassMap
    PropertyBridgePropertySetting.create!(
        property_bridge_id: property_bridge.id,
        property_bridge_property_id: PropertyBridgeProperty.by_property('belongsToClassMap').id,
        value: @class_map.map_name
    )

    predicate = PropertyBridgePropertySetting.create!(
        property_bridge_id: property_bridge.id,
        property_bridge_property_id: PropertyBridgeProperty.by_property('property').id,
        value: ''
    )

    object = PropertyBridgePropertySetting.create!(
        property_bridge_id: property_bridge.id,
        property_bridge_property_id: PropertyBridgeProperty.literal_column.id,
        value: "#{@class_map.table_name}.#{@property_bridge.column_name}"
    )

    language = PropertyBridgePropertySetting.create!(
        property_bridge_id:property_bridge.id,
        property_bridge_property_id: PropertyBridgeProperty.lang.id,
        value:''
    )

    datatype = PropertyBridgePropertySetting.create!(
        property_bridge_id:property_bridge.id,
        property_bridge_property_id: PropertyBridgeProperty.datatype.id,
        value: ''
    )

    condition = PropertyBridgePropertySetting.create!(
        property_bridge_id:property_bridge.id,
        property_bridge_property_id: PropertyBridgeProperty.condition.id,
        value: ''
    )

    {
      predicates: [ predicate ],
      object: object,
      language: language,
      datatype: datatype,
      condition: condition
    }
  end

  def disp_table_selector?(options_for_table_selector)
    return true if options_for_table_selector.size > 1
    return false if options_for_table_selector.empty?

    options_for_table_selector[0][1].size > 1
  end

  def property_bridges_for_column_selector(class_map_id)
    PropertyBridge.where(
        class_map_id: class_map_id,
        property_bridge_type_id: PropertyBridgeType.column.id
    ).order(:id)
  end

  def column_select_choices(class_map)
    property_bridges_for_column_selector(class_map.id).map do |property_bridge|
      [ property_bridge.real_column_name, "#{class_map.table_name}.#{property_bridge.column_name}" ]
    end
  end

  def default_object_value(property_bridge, property)
    class_map = property_bridge.class_map
    table_join = class_map.table_join
    if table_join
      table_name = table_join.r_table.table_name
      "#{table_name}.#{table_join.r_column.real_column_name}"
    else
      table_name = class_map.table_name
      togodb_table = TogodbTable.find_by(name: table_name)
      togodb_column = TogodbColumn.find_by(table_id: togodb_table.id, internal_name: property_bridge.column_name)

      value = if togodb_column
                "#{table_name}.#{togodb_column.name}"
              else
                "#{table_name}.#{property_bridge.column_name}"
              end
      case property
      when 'd2rq:uriPattern'
        "#{table_name}/@@#{value}@@"
      when 'd2rq:pattern'
        "@@#{value}@@"
      else
        togodb_column ? "#{table_name}.#{togodb_column.internal_name}" : "#{table_name}.#{property_bridge.column_name}"
      end
    end
  end

end
