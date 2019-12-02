module Togodb
  class DataRelease
    class << self

      def supported_formats
        %w[csv json rdf ttl fasta]
      end

      def enqueue_job(dataset_id, create_rdf_repository = false)
        drh = TogodbDataReleaseHistory.create!(
            dataset_id: dataset_id,
            submitted_at: Time.now,
            status: 'WAITING'
        )
        Resque.enqueue(Togodb::DataReleaseJob, drh.id, Togodb.dataset_dir, Togodb.tmp_dir, create_rdf_repository)
      end

      def num_running_jobs
        num = 0
        workers = Resque.workers.select { |w| w.queues.include?(Togodb.data_release_queue.to_s) }
        workers.each do |w|
          num += 1 if w.working?
        end

        num
      end

      def create_default_dataset(togodb_table_id)
        columns = TogodbColumn.where(table_id: togodb_table_id, enabled: true).order(:position)
        column_ids = columns.map(&:id).map(&:to_s).join(',')

        TogodbDataset.create!({ table_id: togodb_table_id, name: 'default', columns: column_ids })
      end

      def dataset_file_name(table_name, dataset_name, format)
        basename = "#{table_name}_#{dataset_name}"
        "#{basename}.#{format}"
      end

      def output_file_path(table_name, dataset_name, file_format)
        "#{Togodb.dataset_dir}/#{dataset_file_name(table_name, dataset_name, file_format)}"
      end

      def tmp_file_path(table_name, dataset_name, file_format)
        "#{Togodb.tmp_dir}/#{dataset_file_name(table_name, dataset_name, file_format)}"
      end

      def status_text(dataset)
        h = dataset.latest_history
        if h.status == 'WAITING'
          c = Togodb::DataReleaseHistory.where("status='WAITING' AND id < #{h.id}").count
          "#{h.status} (#{c + 1})"
        else
          h.status
        end
      rescue
        ''
      end

    end
  end
end
