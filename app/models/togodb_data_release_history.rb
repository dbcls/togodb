class TogodbDataReleaseHistory < ApplicationRecord

  belongs_to :dataset, class_name: 'TogodbDataset', foreign_key: 'dataset_id'

end
