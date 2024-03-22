class AddEnvAndReqToTogodbTable < ActiveRecord::Migration[7.0]
  def change
    add_column :togodb_tables, :environment, :integer, default: 0
    add_column :togodb_tables, :requested, :boolean, default: false
  end
end
