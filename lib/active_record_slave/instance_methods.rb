module ActiveRecordSlave
  # Select Methods
  SELECT_METHODS = [:select, :select_all, :select_one, :select_rows, :select_value, :select_values]

  # In case in the future we are forced to intercept connection#execute if the
  # above select methods are not sufficient
  #   SQL_READS = /\A\s*(SELECT|WITH|SHOW|CALL|EXPLAIN|DESCRIBE)/i

  module InstanceMethods
    SELECT_METHODS.each do |select_method|
      # Database Adapter method #exec_query is called for every select call
      # Replace #exec_query with one that calls the slave connection instead
      eval <<-METHOD
      def #{select_method}(sql, name = nil, *args)
        return super if active_record_slave_read_from_master?

        ActiveRecordSlave.read_from_master do
          Slave.connection.#{select_method}(sql, "Slave: \#{name || 'SQL'}", *args)
        end
      end
      METHOD
    end

    # Returns whether to read from the master database
    def active_record_slave_read_from_master?
      # Read from master when forced by thread variable, or
      # in a transaction and not ignoring transactions
      ActiveRecordSlave.read_from_master? ||
        database_name_from_config != database_name_from_raw_connection ||
        (open_transactions > 0) && !ActiveRecordSlave.ignore_transactions?
    end

    def database_name_from_config
      @application_database_name ||= Rails.application.config_for(:database).fetch('database')
    end

    def database_name_from_raw_connection
      @connection_database_name ||= raw_connection.query_options[:database]
    end
  end
end
