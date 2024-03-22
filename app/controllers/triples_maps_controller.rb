class TriplesMapsController < D2RQMapperController
  protect_from_forgery

  include TogoMapper::Mapping
  include TogoMapper::Namespace
  include TriplesMapsHelper

  layout 'd2rq_mapper'

  protect_from_forgery except: [:update]

  before_action :set_class_map, only: %i[show update new_property_bridge_form]
  before_action :set_property_bridge, only: %i[new_property_bridge_form del_property_bridge_form]
  before_action :read_user_required, only: %i[change_subject_format_form change_object_value_form]
  before_action :execute_user_required, only: %i[show update del_property_bridge_form]
  before_action :set_html_body_class

  def index; end

  def create; end

  def new; end

  def edit; end

  def show
    @table_not_found = false

    begin
      db_conn = DBConnection.where(work_id: @class_map.work_id).first
    rescue => e
      flash[:err] = e.message.force_encoding('UTF-8')
      redirect_to config_path(@class_map.work.name)
      return
    end

    begin
      @work = @class_map.work
      maintain_consistency_with_rdb
      if !@class_map.table_name.blank? && !@work.table_exists?(@class_map.table_name)
        @table_not_found = true
        @grouped_triples_maps = options_for_table_selector(@class_map)
      else
        set_instance_variables(@class_map)
        @triples_map_form = triples_map_form_by_rdb
      end
    rescue => e
      logger.fatal e.inspect
      logger.fatal e.backtrace.join("\n")
      flash.now[:err] = 'Sorry, system error has occurred.'
      render action: 'show'
    end
  end

  def update
    ActiveRecord::Base.transaction do
      set_instance_variables(@class_map)
      @triples_map_form = triples_map_form_by_patch_param

      if @triples_map_form.valid?
        @triples_map_form.update!
        flash[:msg] = t('triples_maps.update.success')
      else
        errors = @triples_map_form.errors
        heading = t('triples_maps.update.fail', s: (errors.size > 1 ? 's' : '').to_s)
        flash[:err] = "#{heading}<br />#{errors.full_messages.join('<br />')}"
      end
    end
  rescue => e
    logger.fatal e.inspect
    logger.fatal e.backtrace.join("\n")
    flash[:err] = 'Sorry, system error has occurred.'
  ensure
    redirect_to config_rdf_url(@class_map.table_name)
  end

  def destroy; end

  def new_property_bridge_form
    set_instance_variables(@class_map)

    render 'new_property_bridge_form', layout: false
  end

  def del_property_bridge_form
    ActiveRecord::Base.transaction do
      PropertyBridgePropertySetting.where(property_bridge_id: @property_bridge.id).destroy_all
      PropertyBridge.destroy(@property_bridge.id)
    end

    head :ok
  end

  def new_predicate_form
    render partial: 'predicate_form_for_add', locals: { property_bridge_id: params[:property_bridge_id] }
  end

  def change_subject_format_form
    @class_map_property = ClassMapProperty.find(params[:class_map_property_id])
    @class_map_property_setting = ClassMapPropertySetting.find(params[:class_map_property_setting_id])

    @class_map = @class_map_property_setting.class_map
  end

  def change_object_value_form
    property_bridge = PropertyBridge.find(params[:property_bridge_id])
    @property_bridge_property = PropertyBridgeProperty.find(params[:property_bridge_property_id])
    @class_map = property_bridge.class_map

    @property_set = PropertySetForm.new(property_bridge: property_bridge)
    @property_set.initialize_by_property_bridge
    @property_set.object_value.property_bridge_property_id = @property_bridge_property.id
    @property_set.object_value.value = default_object_value(property_bridge, @property_bridge_property.property)

    @base_uri = Togodb.d2rq_base_uri
    @namespace_prefixes = namespace_prefixes_by_namespace_settings(property_bridge.work.id)
    @property_bridges_for_object_column_selector = PropertyBridge.where(
        class_map_id: property_bridge.class_map.id,
        property_bridge_type_id: PropertyBridgeType.column.id
      ).order(:id)
  end

  private

  def set_class_map
    if params[:class_map_id]
      @class_map = ClassMap.find(params[:class_map_id])
    else
      @class_map = if params[:id] =~ /\A\d+\z/
                     ClassMap.find(params[:id])
                   else
                     ClassMap.where(table_name: params[:id]).reorder('id desc').first
                   end
    end

    @work = Work.find(@class_map.work_id)
    @table = TogodbTable.find_by(name: @work.name)
  end

  def set_property_bridge
    if params[:property_bridge_id]
      @property_bridge = PropertyBridge.find(params[:property_bridge_id])
      @work = @property_bridge.work if @work.blank?
      @table = TogodbTable.find_by(name: @work.name) if @table.blank?
    end
  end

  def set_instance_variables(class_map)
    @db_connection = DBConnection.where(work_id: @work.id).first

    @table_join = class_map.table_join
    @class_map_type = if @table_join
                        'J'
                      else
                        'T'
                      end

    @base_uri = @work.base_uri.blank? ? Togodb.d2rq_base_uri : @work.base_uri
    @class_maps = ClassMap.by_work_id(@work.id)
    @property_bridge_hash = {}
    class_map.column_property_bridges.each do |property_bridge|
      @property_bridge_hash[property_bridge.real_column_name] = property_bridge
    end

    @subject_format_properties = ClassMapProperty.for_resource_identity
    @subject_format_properties << ClassMapProperty.bnode

    # for "Selected table" <select>...</select>
    @grouped_triples_maps = options_for_table_selector(class_map)

    @selected_key = params[:id]

    @object_properties = object_property_bridge_properties
    case @class_map_type
    when 'T'
      @property_bridges_for_subject_column_selector = property_bridges_for_column_selector(@class_map.id)
      @property_bridges_for_object_column_selector = @property_bridges_for_subject_column_selector
    when 'J'
      @property_bridges_for_subject_column_selector = PropertyBridge.where(
          class_map_id: class_map.table_join.l_table.id,
          property_bridge_type_id: PropertyBridgeType.column.id
        ).order(:id)

      @property_bridges_for_object_column_selector = PropertyBridge.where(
          class_map_id: class_map.table_join.r_table.id,
          property_bridge_type_id: PropertyBridgeType.column.id
        ).order(:id)
    end

    @namespace_prefixes = namespace_prefixes_by_namespace_settings(@work.id)

    # Example records
    fetch_example_records(class_map) unless @table_not_found
  end

  def triples_map_form_by_rdb
    triples_map_form = TriplesMapForm.new
    subject_form = SubjectForm.new(class_map: @class_map)
    subject_form.initialize_by_class_map
    triples_map_form.subject = subject_form

    @class_map.property_bridges_for_column.each do |property_bridge|
      property_set_form = PropertySetForm.new(property_bridge: property_bridge)
      property_set_form.initialize_by_property_bridge
      triples_map_form.property_sets << property_set_form
    end

    triples_map_form
  end

  def triples_map_form_by_patch_param
    triples_map_form = TriplesMapForm.new

    triples_map_form.subject = subject_form_by_patch_params

    label_pb = @class_map.property_bridge_for_resource_label
    params['property_bridge'].keys.each do |property_bridge_id|
      next if property_bridge_id.to_i == label_pb.id

      triples_map_form.property_sets << property_set_form_by_patch_params(property_bridge_id)
    end

    triples_map_form
  end

  def subject_form_by_patch_params
    current_rdf_type_cmpses = @class_map.property_settings_for_class

    subject_form = SubjectForm.new(class_map: @class_map)
    subject_form.rdf_types = []

    cmps_ids = params['class_map_property_setting'].to_unsafe_h.keys
    cmps_ids.each do |id|
      cmps_param = params['class_map_property_setting'][id]
      cmps = ClassMapPropertySetting.find(id)
      if cmps_param.key?('class_map_property_id')
        cmps.class_map_property_id = cmps_param['class_map_property_id'].to_i
      end
      if cmps_param.key?('value')
        if (cmps.subject? && cmps.class_map_property_id == ClassMapProperty.uri_pattern.id) || cmps.rdf_type?
          cmps.value = property_setting_value_for_save(Togodb.d2rq_base_uri, cmps_param['value'])
        else
          cmps.value = cmps_param['value']
        end
      end

      if cmps.subject?
        subject_form.uri = cmps
      elsif cmps.rdf_type?
        subject_form.rdf_types << cmps
      elsif cmps.condition?
        subject_form.condition = cmps
      end
    end

    label_pb = @class_map.property_bridge_for_resource_label
    params['property_bridge'][label_pb.id.to_s].keys.each do |pbps_id|
      pbps = PropertyBridgePropertySetting.find(pbps_id)
      pbps.value = params['property_bridge'][label_pb.id.to_s][pbps_id]['value']
      case pbps.property_bridge_property_id
      when PropertyBridgeProperty.literal_pattern.id
        subject_form.label = pbps
      when PropertyBridgeProperty.lang.id
        subject_form.language = pbps
      end
    end

    # Delete rdf:type
    current_rdf_type_cmpses.reject { |cmps| subject_form.rdf_types.map(&:id).include?(cmps.id) }.each(&:destroy!)

    # New rdf:type
    if params['subject_rdf_types']&.is_a?(Array)
      params['subject_rdf_types'].each do |subject_rdf_type|
        next if subject_rdf_type.blank?

        cmps = ClassMapPropertySetting.create!(
            class_map_id: @class_map.id,
            class_map_property_id: ClassMapProperty.rdf_type.id,
            value: subject_rdf_type
          )
        subject_form.rdf_types << cmps
      end
    end

    subject_form
  end

  def property_set_form_by_patch_params(property_bridge_id)
    property_bridge = PropertyBridge.find(property_bridge_id)
    current_predicate_pbpses = property_bridge.predicate

    property_set_form = PropertySetForm.new(property_bridge: property_bridge, predicates: [])
    pb_param = params['property_bridge'][property_bridge_id]
    pb_param.to_unsafe_h.keys.each do |pbps_id|
      if pbps_id.to_s == 'enable'
        property_bridge.enable = pb_param[pbps_id]
      else
        pbps_param = pb_param[pbps_id]
        pbps = PropertyBridgePropertySetting.find(pbps_id)
        if pbps_param.key?('property_bridge_property_id')
          pbps.property_bridge_property_id = pbps_param['property_bridge_property_id'].to_i
        end
        pbps.value = pbps_param['value']

        if pbps.predicate?
          property_set_form.predicates << pbps
        elsif pbps.property_value?
          property_set_form.object_value = pbps
        elsif pbps.language?
          property_set_form.object_language = pbps
        elsif pbps.datatype?
          property_set_form.object_datatype = pbps
        elsif pbps.condition?
          property_set_form.object_condition = pbps
        end
      end
    end

    # Delete predicate
    current_predicate_pbpses.reject { |pbps| property_set_form.predicates.map(&:id).include?(pbps.id) }.each(&:destroy!)

    # New predicate
    if params['predicates'] && params['predicates'][property_bridge_id] && params['predicates'][property_bridge_id].is_a?(Array)
      params['predicates'][property_bridge_id].each do |predicate_uri|
        next if predicate_uri.blank?

        pbps = PropertyBridgePropertySetting.create!(
            property_bridge_id: property_bridge_id,
            property_bridge_property_id: PropertyBridgeProperty.property.id,
            value: predicate_uri
          )
        property_set_form.predicates << pbps
      end
    end

    property_set_form
  end

  def options_for_table_selector(class_map)
    options = []

    opts = ClassMap.table_derived(class_map.work_id).select(&:enable).map { |class_map| [class_map.table_name, class_map.id] }
    options << ['Table'] + [opts] unless opts.empty?

    if TableJoin.exists?(work_id: class_map.work_id)
      opts = TableJoin.by_work_id(class_map.work_id).select { |table_join| table_join.class_map.enable }.map { |table_join| [table_join.label, table_join.class_map.id] }
      options << ['Join'] + [opts] unless opts.empty?
    end

    if BlankNode.exists?(work_id: class_map.work_id)
      opts = ClassMap.where('work_id =? AND bnode_id > 0', class_map.work_id).select(&:enable).map { |class_map| ["Blank node: #{class_map.bnode_id_columns}", class_map.id] }
      options << ['Blank node'] + [opts] unless opts.empty?
    end

    options
  end

  def object_property_bridge_properties
    PropertyBridgeProperty.object_properties
  end

  def fetch_example_records(class_map)
    case @class_map_type
    when 'T'
      table = class_map.table_name
      @exmaple_records_table_name = table
    when 'J'
      table_join = class_map.table_join
      @exmaple_records_table_name = table_join.label
      table = {
          main: {
              table_name: table_join.l_table.table_name,
              key_name: table_join.l_column.real_column_name,
              column_names: table_join.l_table.column_property_bridges.map(&:column_name)
          },
          join: {
              table_name: table_join.r_table.table_name,
              key_name: table_join.r_column.real_column_name,
              column_names: table_join.r_table.column_property_bridges.map(&:column_name)
          }
      }
      if table_join.multiple_join?
        table[:inter] = {
            table_name: table_join.i_table.table_name,
            l_key_name: table_join.i_l_column.real_column_name,
            r_key_name: table_join.i_r_column.real_column_name
        }
      end
    end

    db_client = TogoMapper::DB.new(@db_connection.connection_config)
    @records = db_client.records(table, 0, EXAMPLE_RECORDS_MAX_ROWS)
    deleted_keys = []
    @records.each_with_index do |record, i|
      record.each do |k, v|
        deleted_keys << k if k[0 .. 3] == 'col_'
      end
      deleted_keys.each do |key|
        @records[i][key[4 .. -1]] = @records[i][key]
        @records[i].delete(key)
      end
      deleted_keys = []
    end
    db_client.close
  end

  def set_html_body_class
    @html_body_class = 'page-configure'
  end

end
