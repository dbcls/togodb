module Togodb
  class DatabaseCopyJob
    @queue = Togodb.db_copy_queue

    class << self

      def perform(src_dbid, dst_dbname, copy_data, user_id, authorized_users, key = nil)
        copier = Togodb::DatabaseCopy.new(src_dbid, dst_dbname, copy_data, user_id, authorized_users, key)
        copier.run
      end

    end

  end
end
