class CreateTogodbProductionRequests < ActiveRecord::Migration[7.0]
  def change
    create_table :togodb_production_requests do |t|
      t.integer :table_id, null: false
      t.integer :requester_id
      t.string :email
      t.string :request_comment
      t.string :response_comment
      t.integer :accept

      t.timestamps
    end
  end
end
