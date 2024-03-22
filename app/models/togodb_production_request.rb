class TogodbProductionRequest < ApplicationRecord

  # リクエストが処理済みであれば true を返す
  def processed?
    !accept.nil?
  end

  # TODO リレーションにする
  def table
    TogodbTable.find(table_id)
  end
end
