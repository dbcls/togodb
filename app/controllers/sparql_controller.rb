require 'tempfile'
require 'open3'
require 'togo_mapper/d2rq/mapping_generator'
require 'togo_mapper/namespace'

class SparqlController < D2RQMapperController
  include TogoMapper::Namespace

  before_action :set_work
  before_action :read_user_required
  before_action :set_html_body_class
  protect_from_forgery except: [:show, :search]

  RESPONSE_MIME_TYPE_JSON = 'application/sparql-results+json'
  RESPONSE_MIME_TYPE_XML = 'application/sparql-results+xml'

  def show
    if params[:query]
      if request.headers['Accept'].blank? || request.headers['Accept'] != '*/*'
        format = format_by_accept_header(request.headers['Accept'])
      else
        format = 'json'
      end
      content_type = content_type_by_format(format)

      if Togodb.use_graphdb
        result = sparql_query_to_graphdb(@work.name, params[:query], format)
        render plain: result, content_type: content_type
      else
        execute_sparql(params[:query], format)
        if @status.success?
          render plain: @result, content_type: content_type
        else
          render plain: @stderr, status: :bad_request
        end
      end
    else
      referer = request.headers['Referer']
      @show_left_menu = [ d2rq_mapping_url(@work.name), r2rml_mapping_url(@work.name), turtle_url(@work.name) ].include?(referer)
      @prefixes = sparql_prefixes(@work.id)

      if @show_left_menu
        render layout: 'graph'
      else
        @html_body_class = "#{@html_body_class} nomenu"
      end
    end
  end

  def search
    database_name = params[:id]
    sparql = params[:query].to_s.strip
    format = params[:output_format]
    if params[:sparql_backend].to_s == 'd2rq' || !Togodb.use_graphdb
      execute_sparql(sparql, format)
    else
      @result = sparql_query_to_graphdb(database_name, sparql, format)
      @result.force_encoding('UTF-8')
    end
  end

  private

  def sparql_query_to_graphdb(database_name, sparql, format)
    graphdb_uri = URI.parse(Togodb.graphdb_server)
    grapdb = Graphdb::Rest.new(graphdb_uri.host, graphdb_uri.port, graphdb_uri.scheme == 'https')
    grapdb.sparql_query(database_name, sparql, format)
  end

  def execute_sparql(sparql, format)
    set_instance_variables_for_mapping_data(@class_map.table_name)
    @password = @db_connection.decrypt_password

    mapping_generator = TogoMapper::D2RQ::MappingGenerator.new
    mapping_generator.prepare_by_work(@work)
    mapping_generator.password = @password
    mapping_file_path = Tempfile.open(['d2rq-', '-mapping.ttl'], "#{Rails.root}/tmp") do |fp|
      fp.print mapping_generator.generate
      fp.path
    end

    cmd_parts = ["#{TogoMapper.d2r_query} -f #{format} --timeout 60"]
    if @work.base_uri.blank?
      cmd_parts << "-b http://#{Togodb.app_server}/db/"
    else
      cmd_parts << "-b #{@work.base_uri}"
    end
    cmd_parts << "#{mapping_file_path} '#{sparql}'"

    @password = ''

    cmd = cmd_parts.join(' ')
    logger.debug cmd

    @result, @stderr, @status = Open3.capture3(cmd)

    logger.debug "===== STDOUT =====\n#{@result}"
    logger.debug "===== STDERR =====\n#{@stderr}"
    logger.debug "===== STATUS =====\n#{@status}"
  end

  def response_mime_type_by_accept_header(accept_header)
    cts = accept_header.to_s.split(';').first.split(',')
    if cts.include?(RESPONSE_MIME_TYPE_XML)
      RESPONSE_MIME_TYPE_XML
    else
      RESPONSE_MIME_TYPE_JSON
    end
  end

  def format_by_accept_header(accept_header)
    cts = accept_header.split(';')[0].split(',')
    if cts.include?(RESPONSE_MIME_TYPE_XML)
      'xml'
    elsif cts.include?(RESPONSE_MIME_TYPE_JSON)
      'json'
    else
      'json'
    end
  end

  def content_type_by_format(format)
    case format.to_s
    when 'json'
      RESPONSE_MIME_TYPE_JSON
    when 'xml'
      RESPONSE_MIME_TYPE_XML
    else
      RESPONSE_MIME_TYPE_JSON
    end
  end

  def sparql_prefixes(work_id)
    namespaces = namespaces_by_namespace_settings(work_id)
    namespaces.select do |namespace|
      !%w(d2rq jdbc map).include?(namespace[:prefix])
    end.map do |namespace|
      "PREFIX #{namespace[:prefix].strip}: <#{namespace[:uri].strip}>"
    end.join("\n")
  end

  def set_html_body_class
    @html_body_class = 'page-get sparql'
  end

end
