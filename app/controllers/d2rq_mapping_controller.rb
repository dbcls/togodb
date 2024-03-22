class D2RQMappingController < D2RQMapperController
  before_action :set_table, only: [:show]
  before_action :set_work, only: [:download]
  before_action :read_user_required, only: [:show, :download]
  before_action :set_html_body_class

  layout 'd2rq_mapper'

  def show
    @class_map = ClassMap.where(table_name: @table.name).reorder(id: :desc).first
    @work = @class_map.work

    mapping_generator = TogoMapper::D2RQ::MappingGenerator.new
    mapping_generator.prepare_by_work(@work)
    @mapping_data = mapping_generator.generate

    #if xhr?
    if false
      set_headers_for_cross_domain
      response_json
    else
      respond_to do |format|
        format.html { render layout: 'graph' }
        format.ttl { render text: @mapping_data, content_type: 'text/plain' }
      end
    end
  end

=begin
  def download
    mapping_generator = TogoMapper::D2RQ::MappingGenerator.new
    mapping_generator.prepare_by_work(@work)

    send_data(
      mapping_generator.generate,
      filename: "#{@work.name}-d2rq-mapping.ttl", type: 'text/turtle'
    )
  end


  def by_table
    class_map = ClassMap.find(params[:id])
    @work = class_map.work
    validate_user(@work.id)
    
    mapping_generator = TogoMapper::D2RQ::MappingGenerator.new
    mapping_generator.prepare_by_class_map(class_map)
    @mapping_data = mapping_generator.generate_by_class_map

    if xhr?
      set_headers_for_cross_domain
      response_json
    else
      render text: @mapping_data, content_type: 'text/plain'
    end
  end


  def by_column
    property_bridge = PropertyBridge.find(params[:id])
    @work = property_bridge.work
    validate_user(@work.id)
    
    mapping_generator = TogoMapper::D2RQ::MappingGenerator.new
    mapping_generator.prepare_by_property_bridge(property_bridge)
    @mapping_data = mapping_generator.generate_by_property_bridge

    if xhr?
      if json?
        set_headers_for_cross_domain
        response_json
      else
        response_js
      end
    else
      render text: @mapping_data, content_type: 'text/plain'
    end
  end

  def by_table_join
    table_join = TableJoin.find(params[:id])
    @work = table_join.work
    validate_user(@work.id)
    
    mapping_generator = TogoMapper::D2RQ::MappingGenerator.new
    mapping_generator.prepare_by_table_join(table_join)
    @mapping_data = mapping_generator.generate_by_table_join

    render text: @mapping_data, content_type: 'text/plain'
  end
=end

  private

  def generate_d2rq_mapping
    mapping_generator = TogoMapper::D2RQ::MappingGenerator.new
    mapping_generator.prepare_by_work(@work.id)
  end

  def set_html_body_class
    @html_body_class = 'rdf page-get'
  end

  def response_json
    data = common_json_data('100')
    data[:d2rq_mapping] = @mapping_data

    render_json(data)
  end

end
