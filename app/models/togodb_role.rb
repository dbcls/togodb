class TogodbRole < ApplicationRecord

  belongs_to :table, class_name: 'TogodbTable', foreign_key: 'table_id'
  belongs_to :user, class_name: 'TogodbUser', foreign_key: 'user_id'

  include ActsAsBits
  acts_as_bits :roles,  %w( admin read write execute ), prefix: true

  #attr_accessible :roles, :table_id, :user_id, :role_admin, :role_read, :role_write, :role_execute

  class << self
    def instance(table, user)
      role = find_by(table_id: table.id, user_id: user.id)
      role ||= create!(table_id: table.id, user_id: user.id)

      role
    end

    def create_admin_role!(table_id, user_id)
      create!(table_id: table_id, user_id: user_id, roles: '1000')
    end

    def executable_users(table_id)
      user_ids = TogodbRole.where("SUBSTR(roles, 1, 1) = '1'").or(TogodbRole.where("SUBSTR(roles, 4, 1) = '1'")).where(table_id: table_id).map(&:user_id)
      TogodbUser.where(id: user_ids)
    end

    def executable_table_ids(user_id)
      TogodbRole.where("SUBSTR(roles, 1, 1) = '1'").or(TogodbRole.where("SUBSTR(roles, 4, 1) = '1'")).where(user_id: user_id).map(&:table_id)
    end
  end

end
