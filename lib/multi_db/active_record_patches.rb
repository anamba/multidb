module ActiveRecord
  class Base
    class << self
      
      def master_configuration(env = nil)
        env ||= Rails.env
        
        # use master db configuration in config/database.yml if present
        configurations["master_#{env}"] or Proc.new {
          c = configurations[env].dup
          c['database'] += '_master'
          c
        }.call
      end
      
      def connect_to_sessions
        config = configurations[Rails.env || 'development']
        self.establish_connection(config)
      end
      
      def connect_to_master
        self.establish_connection(master_configuration)
      end
      
      def connect_to_organization(org = nil, set_env = false)
        org_code = org.is_a?(MultiDB::Organization) ? org.code : org
        org_code ||= ENV['RAILS_ORG'] || 'org1'
        
        config = ActiveRecord::Base.configurations[Rails.env]
        self.establish_connection(config.merge('database' => "#{config['database']}_#{org_code}"))
        
        begin
          ActiveRecord::Base.connection.tables
        rescue Mysql2::Error
          Rails.logger.error "Couldn't connect to org db for #{org_code}"
          return false
        end
        
        ENV['RAILS_ORG'] = org_code if set_env
        org_code
      end
    end
  end
  
  class Migration
    
    alias_method :migrate_without_multidb, :migrate
    def migrate(direction)
      if ENV['RAILS_ORG'] == 'master'
        Base.connect_to_master
      elsif ENV['RAILS_ORG'] == 'sessions'
        Base.connect_to_sessions
      else
        Base.connect_to_organization
      end
      
      migrate_without_multidb(direction)
    end
    
  end
  
  class Migrator
    
    alias_method :initialize_without_multidb, :initialize
    def initialize(direction, migrations_paths, target_version = nil)
      if ENV['RAILS_ORG'] == 'master'
        Base.connect_to_master
      elsif ENV['RAILS_ORG'] == 'sessions'
        Base.connect_to_sessions
      else
        Base.connect_to_organization
      end
      
      initialize_without_multidb(direction, migrations_paths, target_version)
    end
    
    class << self
      
      def migrations_paths
        @migrations_paths ||= ['db/migrate']
        # just to not break things if someone uses: migration_path = some_string
        paths = Array.wrap(@migrations_paths)
        
        case ENV['RAILS_ORG']
        when 'sessions', 'master'
          paths.map { |path| "#{path}/#{ENV['RAILS_ORG']}" }
        else
          paths.map { |path| "#{path}/org" }
        end
      end
      
    end
  end
end
