class AddMetastanzaTableJsonToTogodbTable < ActiveRecord::Migration[7.1]
  def change
    add_column :togodb_tables, :metastanza_table_json, :text
  end
end
