class TogodbDataset < ApplicationRecord

  has_many :release_histories, -> { order(released_at: :desc) },
           class_name: 'TogodbDataReleaseHistory', foreign_key: 'dataset_id', dependent: :delete_all
  belongs_to :table, class_name: 'TogodbTable', foreign_key: 'table_id'


  class << self

    def setting_counts(table_id)
      counts = {}
      Togodb::DataReleaseFileSetting.all.each do |drfs|
        cnt = where(data_release_file_setting_id: drfs.id, table_id: table_id).count
        counts[drfs.file_format] = cnt
      end

      counts
    end

    def default_setting(table_id)
      find_by(table_id: table_id, name: 'default')
    end

  end


  def column_list
    return [] if columns.nil?

    columns.split(',').map { |id| TogodbColumn.find(id) }.select(&:enabled)
  end

  def latest_history
    TogodbDataReleaseHistory.where(dataset_id: id).order('id DESC').first
  end

  def can_submit_job?
    h = latest_history
    !h || (h.status != 'RUNNING' && h.status != 'WAITING')
  end

  def fasta_sequence_column
    TogodbColumn.find(fasta_seq_column_id)
  end

  def default?
    name == 'default'
  end

  def released?
    released_at.blank? ? false : true
  end

  def released_at
    at = TogodbDataReleaseHistory.where(dataset_id: id).order('released_at DESC').first

    at ? at.released_at : ''
  end

  def status_text
    history = latest_history
    if history
      if history.status == 'WAITING'
        num_waiting = TogodbDataReleaseHistory.where('status=? AND id<?', 'WAITING', history.id).count
        "#{history.status} (#{num_waiting + 1})"
      else
        history.status
      end
    else
      ''
    end
  rescue
    ''
  end

  def update_rdf_repository?
    name == 'default'
  end

end
