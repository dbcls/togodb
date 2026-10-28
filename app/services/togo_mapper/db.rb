module TogoMapper
  class DB
    attr_reader :connection_config, :client

    def initialize(connection_config)
      @connection_config = connection_config.dup

      adapter = connection_config.delete(:adapter)
      case adapter
      when 'mysql2'
        @client = TogoMapper::DB::Mysql.new(connection_config)
      when 'postgresql'
        @client = TogoMapper::DB::Pgsql.new(connection_config)
      when 'sqlite3'
        @client = TogoMapper::DB::SQLite.new(connection_config)
      end
    end

    def tables
      @client.tables
    end

    def columns(table)
      @client.columns(table)
    end

    def records(table, offset = 0, limit = 5)
      @client.records(table, offset, limit)
    end

    def close
      @client.close
    end

  end
end
