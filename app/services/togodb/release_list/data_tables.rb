module Togodb
  class ReleaseList
    class DataTables < Togodb::DataTables
      include ActionView::Helpers::NumberHelper
      include ActionView::Helpers::UrlHelper
      include Togodb::Management

      class << self
        def columns
          [
              {
                  name: 'name',
                  label: 'Name',
                  method: 'name_text',
                  prop: '{"sClass": "left"}'
              },
              {
                  name: 'dataset_name',
                  label: 'Dataset',
                  method: 'dataset_text',
                  prop: '{"sClass": "left"}'
              },
              {
                  name: 'csv_size',
                  label: 'CSV',
                  method: 'csv_file_size_text',
                  prop: '{"sClass": "right", "bSortable": false}'
              },
              {
                  name: 'json_size',
                  label: 'JSON',
                  method: 'json_file_size_text',
                  prop: '{"sClass": "right", "bSortable": false}'
              },
              {
                  name: 'turtle_size',
                  label: 'RDF (Turtle)',
                  method: 'ttl_file_size_text',
                  prop: '{"sClass": "right", "bSortable": false}'
              },
              {
                  name: 'rdfxml_size',
                  label: 'RDF (XML)',
                  method: 'rdfxml_file_size_text',
                  prop: '{"sClass": "right", "bSortable": false}'
              },
              {
                  name: 'fasta_size',
                  label: 'FASTA',
                  method: 'fasta_file_size_text',
                  prop: '{"sClass": "right", "bSortable": false}'
              },
              {
                  name: 'released_at',
                  label: 'Release date',
                  method: 'released_at_text',
                  prop: '{"sClass": "left", "bSortable": false}'
              },
              {
                  name: 'status',
                  label: 'Status',
                  method: 'status_text',
                  prop: '{"sClass": "left", "bSortable": false}'
              },
              {
                  name: 'action',
                  label: 'Action',
                  method: 'action_text',
                  prop: '{"sClass": "left", "bSortable": false}'
              }
          ]
        end
      end

      def initialize(datatables_params, current_user)
        @current_user = current_user
        super(datatables_params)
      end

      def list_records
        if tables.empty?
          @filtered_total = 0
          return []
        end

        @filtered_total = TogodbDataset.includes(:table).where(list_conditions).references(:table).count
        TogodbDataset.includes(:table).where(list_conditions).references(:table).offset(list_offset).limit(list_limit).order(list_orders.join(','))
      end

      def list_orders
        if num_sort_columns == 0
          orders = ['togodb_tables.name ASC']
        else
          orders = []
          num_sort_columns.times do |i|
            if sort_field(i) == 'name'
              orders << "togodb_tables.name #{sort_dir(i)}, togodb_datasets.id ASC"
            else
              orders << "#{sort_field(i)} #{sort_dir(i)}, togodb_datasets.id ASC"
            end
          end
        end

        orders
      end

      def name_text(record)
        if allow_read_data?(@current_user, record.table)
          "<a href=\"/db/#{record.table.name}\">#{record.table.name}</a>"
        else
          record.table.name
        end
      rescue
        '[Unknown]'
      end

      def dataset_text(record)
        record.name
      rescue
        '[Unknown]'
      end

      def csv_file_size_text(record)
        data_download_link(record.table, record.name, 'csv')
      rescue
        ''
      end

      def json_file_size_text(record)
        data_download_link(record.table, record.name, 'json')
      rescue
        ''
      end

      def rdfxml_file_size_text(record)
        data_download_link(record.table, record.name, 'rdf')
      rescue
        ''
      end

      def ttl_file_size_text(record)
        data_download_link(record.table, record.name, 'ttl')
      rescue
        ''
      end

      def fasta_file_size_text(record)
        data_download_link(record.table, record.name, 'fasta')
      rescue
        ''
      end

      def released_at_text(record)
        record.latest_history.released_at.to_s
      rescue
        ''
      end

      def status_text(record)
        Togodb::DataRelease.status_text(record)
      end

      def release_text(record)
        h = record.latest_history
        if h.status == 'RUNNING' || h.status == 'WAITING'
          ''
        else
          table = TogodbTable.find(record.table_id)
          if allow_execute?(@current_user, table)
            #link_to_remote 'Release', :method => 'get', :url => {:controller => 'togodb_data_release', :action => 'release', :id => record.id}
            #"<a href=\"#\" onclick=\"jQuery.ajax({dataType:'script', type:'get', url:'/release/ds/#{record.id}'}); return false;\">Release</a>"
            link_to 'Release', release_togodb_dataset_path(dataset), remote: true
          else
            ''
          end
        end
      rescue
        ''
      end

      def action_text(record)
        actions = []
        begin
          table = TogodbTable.find(record.table_id)
          allow_execute = allow_execute?(@current_user, table)

          if allow_execute
            actions << "<a href=\"/config/#{table.name}\">Config</a>"
          end

          h = record.latest_history
          if (!h || (h.status != 'RUNNING' && h.status != 'WAITING')) && allow_execute
            actions << link_to('Release', "/togodb_datasets/#{record.id}/release", remote: true)
          end
          actions.join(' | ')
        rescue ActiveRecord::RecordNotFound
          ''
        end
      end

      def data_download_link(table, dataset_name, format)
        if table.dl_file_name.blank?
          base_name = table.name
        else
          base_name = table.dl_file_name
        end

        text = ''
        begin
          text = file_size(table.name, dataset_name, format)
          if allow_read_data?(@current_user, table)
            if text.blank?
              text
            else
              if dataset_name == 'default'
                fname = "#{base_name}.#{format}"
              else
                fname = "#{base_name}-#{dataset_name}.#{format}"
              end
              "<a href=\"/release/#{fname}\">#{text}</a>"
            end
          else
            text
          end
        rescue
          text
        end
      end

      def file_size(table_name, dataset_name, format)
        fpath = "#{Togodb.dataset_dir}/#{table_name}_#{dataset_name}.#{format}"
        if File.exist?(fpath)
          number_with_delimiter File.size(fpath)
        else
          ''
        end
      end

    end
  end
end
