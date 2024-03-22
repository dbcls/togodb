class CreateTogodbGraphs < ActiveRecord::Migration[7.1]
  def change
    create_table :togodb_graphs do |t|
      t.references :togodb_column, null: false, foreign_key: true
      t.text :embed_tag

      t.timestamps
    end
  end
end
