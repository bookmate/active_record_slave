ENV['RAILS_ENV'] = 'test'

require 'active_record'
require 'minitest/autorun'
require 'active_record_replica'
require 'awesome_print'
require 'logger'
require 'erb'

l                                 = Logger.new('test.log')
l.level                           = ::Logger::DEBUG
ActiveRecord::Base.logger         = l
ActiveRecord::Base.configurations = YAML::load(ERB.new(IO.read('test/database.yml')).result)

def config(env_name)
  configs = ActiveRecord::Base.configurations
  if ActiveRecord.version >= Gem::Version.new('6.1')
    configs.configs_for(env_name: env_name.to_s)[0].configuration_hash
  else
    configs[env_name.to_s]
  end.deep_symbolize_keys
end

def create_database(config)
  name = config[:database]
  ActiveRecord::Base.establish_connection(config.except(:database))
  ActiveRecord::Base.connection.create_database(name)
rescue ActiveRecord::StatementInvalid
  ActiveRecord::Base.logger.error("Database '#{name}' already exists")
end

def load_schema(database_config, &block)
  ActiveRecord::Base.establish_connection(database_config)
  block.call
end

def prepare_database(config, &block)
  create_database(config)
  load_schema(config, &block)
end

# AR Models
class User < ActiveRecord::Base
end

class Book < ActiveRecord::Base
  establish_connection(:other)
end

def define_common_database_schema
  ActiveRecord::Schema.define :version => 0 do
    create_table :users, :force => true do |t|
      t.string :name
      t.string :address
    end
  end
end

# Define Schema in primary database
prepare_database(config(:test)) do
  define_common_database_schema
end

# Define Schema in second database (replica)
# Note: This is not be required when the primary database is being replicated to the replica db
prepare_database(config(:test)[:slave]) do
  define_common_database_schema
  User.create!(name: 'slave')
end

# Define Schema in slow second database (slow replica)
prepare_database(config(:test)[:slow_slave]) do
  define_common_database_schema
  User.create!(name: 'slow slave')
end

# Define Schema in other database
prepare_database(config(:other)) do
  ActiveRecord::Schema.define :version => 0 do
    create_table :books, :force => true do |t|
      t.string :title
    end
  end
end

# Establish connection to main database
ActiveRecord::Base.establish_connection(:test)

# Install ActiveRecord replica. Done automatically by railtie in a Rails environment
# Also tell it to use the test environment since Rails.env is not available
ActiveRecordReplica.main_database_name = 'test'
ActiveRecordReplica.install!(nil, 'test', [:slave, :slow_slave], default: :slave)
