module Togodb
  module Management

    def togodb_tables(user, order = 'name')
      return [] unless user

      if user.superuser?
        TogodbTable.order(order)
      else
        roles = TogodbRole.where(user_id: user.id)
        if roles.empty?
          TogodbTable.where(creator_id: user.id).order(order)
        else
          TogodbTable.where(creator_id: user.id).or(TogodbTable.where(id: roles.map(&:table_id))).order(order)
        end
      end
    end

    def togodb_table_instance_by_name(name)
      togodb_table = TogodbTable.find_by_page_name(name)
      if togodb_table.nil?
        togodb_table = TogodbTable.find_by_name(name)
      end

      togodb_table
    end

    def allow_read_data?(user, db)
      db.enabled || user&.read_table?(db)
    end

    def allow_write_data?(user, db)
      user&.write_table?(db)
    end

    def allow_execute?(user, db)
      user&.execute_table?(db)
    end

    def admin_user?(user, db)
      user&.admin_table?(db)
    end

  end
end
