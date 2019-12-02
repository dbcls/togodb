class TogodbCreate < ApplicationRecord

  belongs_to :table, class_name: 'TogodbTable', foreign_key: 'table_id'

end
