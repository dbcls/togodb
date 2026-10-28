module Togodb
  module DatabaseCopier
    class InvalidTableName < RuntimeError
    end

    class InvalidParameter < RuntimeError
    end

    class SystemError < RuntimeError
    end

    include Togodb::FileUtils
    include Togodb::StringUtils

    def copy_database
      key = random_str(16)
      if @copy_data
        Resque.enqueue Togodb::DatabaseCopyJob, @table.id, @dst_dbname, true, @user.id, @authorized_users, key
      else
        db_copy = Togodb::DatabaseCopy.new(@table.id, @dst_dbname, false, @user.id, key)
        db_copy.run
      end

      key
    end

    def dst_database_valid?
      if @dst_dbname.blank?
        raise InvalidParameter, 'New database name is not specified.'
      end

      unless Togodb.valid_table_name?(@dst_dbname)
        raise InvalidParameter, 'New database name is invalid.'
      end

      if Togodb.reserved_table_name?(@dst_dbname)
        raise InvalidParameter, "New database name '#{@dst_dbname}' can not be used."
      end

      if TogodbTable.exists?(['name=? OR page_name=?', @dst_dbname, @dst_dbname])
        raise InvalidParameter, "Database '#{@dst_dbname}' already exists."
      end

      begin
        model = TogodbTable.new(name: @dst_dbname).class_name
        klass = model.constantize
        if klass.is_a?(Class)
          raise InvalidParameter, "Database '#{@dst_dbname}' conflicts with system name '#{model}'."
        end
      rescue NameError
        # no conflicts
      else
        raise SystemError, 'System error.'
      end
    end

  end
end
