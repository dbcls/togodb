class R2RMLMappingController < D2RQMapperController
  include TogoMapper::R2RML
  include TogoMapper::Namespace

  before_action :set_table
  before_action :read_user_required
  before_action :set_html_body_class

  layout 'd2rq_mapper'

  def show
    set_instance_variables_for_mapping_data(params[:id])
    @mapping_data = generate_mapping

    if xhr?
      set_headers_for_cross_domain
      response_json
    else
      respond_to do |format|
        format.html { render layout: 'graph' }
        format.ttl  { render text: @mapping_data, content_type: 'text/plain' }
      end
    end
  end

  def download
    set_instance_variables_for_mapping_data(params[:id])

    send_data(
      generate_mapping,
      filename: "#{@work.name}-r2rml-mapping.ttl", type: 'text/turtle'
    )
  end

  private

  def set_html_body_class
    @html_body_class = 'rdf page-get'
  end

  def response_json
    data = common_json_data('100')
    data[:r2rml_mapping] = @mapping_data

    render_json(data)
  end

end
