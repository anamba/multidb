#
# Based on activerecord-4.0.2/lib/active_record/railties/databases.rake
#
# AKN: Warning! All code to support db engines other than mysql has been deleted,
#      since I know it will never receive proper testing.
#

tasks = Rake.application.instance_variable_get '@tasks'
tasks.delete 'db:migrate'
tasks.delete 'db:migrate:up'
tasks.delete 'db:migrate:down'
tasks.delete 'db:rollback'
tasks.delete 'db:forward'
tasks.delete 'db:schema:dump'
tasks.delete 'db:schema:load'
tasks.delete 'db:test:load_schema'
tasks.delete 'db:test:purge'


db_namespace = namespace :db do
  namespace :create do
    desc 'Runs create for sessions and master databases.'
    task :multi => [:load_config] do
      [ 'sessions', 'master' ].each do |org|
        ENV['RAILS_ORG'] = org
        db_namespace[:create].execute
      end
    end
  end
  
  namespace :drop do
    desc 'Runs drop for sessions and master databases.'
    task :multi => [:load_config] do
      [ 'sessions', 'master' ].each do |org|
        ENV['RAILS_ORG'] = org
        db_namespace[:drop].execute
      end
    end
  end
  
  namespace :setup do
    desc 'Runs setup for sessions and master databases.'
    task :multi => [:load_config] do
      [ 'sessions', 'master' ].each do |org|
        ENV['RAILS_ORG'] = org
        db_namespace[:create].execute
        db_namespace['schema:load'].execute
        db_namespace[:seed].execute
      end
    end
  end
  
  namespace :migrate do
    desc 'Runs migrate for sessions, master and org databases.'
    task :multi => [:environment, :load_config] do
      puts "=========================================================="
      puts "===== SESSIONS"
      puts "=========================================================="
      puts
      ENV['RAILS_ORG'] = 'sessions'
      db_namespace[:migrate].execute
      puts
      
      puts "=========================================================="
      puts "===== MASTER"
      puts "=========================================================="
      puts
      ENV['RAILS_ORG'] = 'master'
      db_namespace[:migrate].execute
      puts
      
      puts "=========================================================="
      puts "===== ORGANIZATIONS"
      puts "=========================================================="
      puts
      ENV['RAILS_ORG'] = nil
      db_namespace[:migrate].execute
      puts
    end
    
    # desc 'Runs the "up" for a given migration VERSION.'
    task :up => [:environment, :load_config] do
      version = ENV['VERSION'] ? ENV['VERSION'].to_i : nil
      raise 'VERSION is required' unless version
      
      if ENV['RAILS_ORG'] == 'sessions' || ENV['RAILS_ORG'] == 'all'
        ActiveRecord::Base.connect_to_sessions
        ActiveRecord::Migrator.run(:up, ActiveRecord::Migrator.migrations_paths, version)
        db_namespace['_dump'].invoke
      end
      
      if ENV['RAILS_ORG'] == 'master' || ENV['RAILS_ORG'] == 'all'
        ActiveRecord::Base.connect_to_master
        ActiveRecord::Migrator.run(:up, ActiveRecord::Migrator.migrations_paths, version)
        db_namespace['_dump'].invoke
      end
      
      if ENV['RAILS_ORG'] == 'all' || ![ 'sessions', 'master' ].include?(ENV['RAILS_ORG'])
        schema_dumped = false
        MultiDB::Organization.active.each do |org|
          ActiveRecord::Base.connect_to_organization(org, true)
          ActiveRecord::Migrator.run(:up, ActiveRecord::Migrator.migrations_paths, version)
          db_namespace['_dump'].invoke unless schema_dumped
          schema_dumped = true
        end
      end
    end
    
    # desc 'Runs the "down" for a given migration VERSION.'
    task :down => [:environment, :load_config] do
      version = ENV['VERSION'] ? ENV['VERSION'].to_i : nil
      raise 'VERSION is required' unless version
      
      if ENV['RAILS_ORG'] == 'sessions'
        ActiveRecord::Base.connect_to_sessions
        ActiveRecord::Migrator.run(:down, ActiveRecord::Migrator.migrations_paths, version)
        db_namespace['_dump'].invoke
      end
      
      if ENV['RAILS_ORG'] == 'master'
        ActiveRecord::Base.connect_to_master
        ActiveRecord::Migrator.run(:down, ActiveRecord::Migrator.migrations_paths, version)
        db_namespace['_dump'].invoke
      end
      
      if ![ 'sessions', 'master' ].include?(ENV['RAILS_ORG'])
        schema_dumped = false
        MultiDB::Organization.active.each do |org|
          ActiveRecord::Base.connect_to_organization(org, true)
          ActiveRecord::Migrator.run(:down, ActiveRecord::Migrator.migrations_paths, version)
          db_namespace['_dump'].invoke unless schema_dumped
          schema_dumped = true
        end
      end
    end
  end
  
  desc "Migrate the database (options: VERSION=x, VERBOSE=false)."
  task :migrate => [:environment, :load_config] do
    ActiveRecord::Migration.verbose = ENV["VERBOSE"] ? ENV["VERBOSE"] == "true" : true
    
    if ENV['RAILS_ORG'] == 'sessions'
      ActiveRecord::Base.connect_to_sessions
      ActiveRecord::Migrator.migrate(ActiveRecord::Migrator.migrations_paths, ENV["VERSION"] ? ENV["VERSION"].to_i : nil) do |migration|
        ENV["SCOPE"].blank? || (ENV["SCOPE"] == migration.scope)
      end
      db_namespace['_dump'].invoke
    end
    
    if ENV['RAILS_ORG'] == 'master'
      ActiveRecord::Base.connect_to_master
      ActiveRecord::Migrator.migrate(ActiveRecord::Migrator.migrations_paths, ENV["VERSION"] ? ENV["VERSION"].to_i : nil) do |migration|
        ENV["SCOPE"].blank? || (ENV["SCOPE"] == migration.scope)
      end
      db_namespace['_dump'].invoke
    end
    
    if ![ 'sessions', 'master' ].include?(ENV['RAILS_ORG'])
      schema_dumped = false
      MultiDB::Organization.active.each do |org|
        puts "== Migrating: #{org.code}"
        ActiveRecord::Base.connect_to_organization(org, true)
        ActiveRecord::Migrator.migrate(ActiveRecord::Migrator.migrations_paths, ENV["VERSION"] ? ENV["VERSION"].to_i : nil) do |migration|
          ENV["SCOPE"].blank? || (ENV["SCOPE"] == migration.scope)
        end
        db_namespace['_dump'].invoke unless schema_dumped
        schema_dumped = true
      end
    end
  end
  
  desc 'Rolls the schema back to the previous version (specify steps w/ STEP=n).'
  task :rollback => [:environment, :load_config] do
    step = ENV['STEP'] ? ENV['STEP'].to_i : 1
    
    if ENV['RAILS_ORG'] == 'sessions'
      ActiveRecord::Base.connect_to_sessions
      ActiveRecord::Migrator.rollback(ActiveRecord::Migrator.migrations_paths, step)
      db_namespace['_dump'].invoke
    end
    
    if ENV['RAILS_ORG'] == 'master'
      ActiveRecord::Base.connect_to_master
      ActiveRecord::Migrator.rollback(ActiveRecord::Migrator.migrations_paths, step)
      db_namespace['_dump'].invoke
    end
    
    if ![ 'sessions', 'master' ].include?(ENV['RAILS_ORG'])
      schema_dumped = false
      MultiDB::Organization.active.each do |org|
        puts "== Rollback: #{org.code}"
        ActiveRecord::Base.connect_to_organization(org, true)
        ActiveRecord::Migrator.rollback(ActiveRecord::Migrator.migrations_paths, step)
        db_namespace['_dump'].invoke unless schema_dumped
        schema_dumped = true
      end
    end
  end
  
  # desc 'Pushes the schema to the next version (specify steps w/ STEP=n).'
  task :forward => [:environment, :load_config] do
    step = ENV['STEP'] ? ENV['STEP'].to_i : 1
    
    if ENV['RAILS_ORG'] == 'sessions'
      ActiveRecord::Base.connect_to_sessions
      ActiveRecord::Migrator.forward(ActiveRecord::Migrator.migrations_paths, step)
      db_namespace['_dump'].invoke
    end
    
    if ENV['RAILS_ORG'] == 'master'
      ActiveRecord::Base.connect_to_master
      ActiveRecord::Migrator.forward(ActiveRecord::Migrator.migrations_paths, step)
      db_namespace['_dump'].invoke
    end
    
    if ![ 'sessions', 'master' ].include?(ENV['RAILS_ORG'])
      schema_dumped = false
      MultiDB::Organization.active.each do |org|
        ActiveRecord::Base.connect_to_organization(org, true)
        ActiveRecord::Migrator.forward(ActiveRecord::Migrator.migrations_paths, step)
        db_namespace['_dump'].invoke unless schema_dumped
        schema_dumped = true
      end
    end
  end
  
  namespace :schema do
    desc 'Create a db/schema.rb file that can be portably used against any DB supported by AR'
    task :dump => [:environment, :load_config] do
      require 'active_record/schema_dumper'
      
      databases_to_dump = case ENV['RAILS_ORG']
        when nil then [ :sessions, :master ]
        when 'sessions' then [ :sessions ]
        when 'master' then [ :master ]
        else [ :organization ]
      end
      
      databases_to_dump.each do |db|
        ActiveRecord::Base.send("connect_to_#{db}")
        filename = ENV['SCHEMA'] || "#{Rails.root}/db/schema_#{db}.rb"
        File.open(filename, "w:utf-8") do |file|
          ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, file)
        end
      end
      db_namespace['schema:dump'].reenable
    end
    
    desc 'Load a schema.rb file into the database'
    task :load => [:environment, :load_config] do
      databases_to_load = case ENV['RAILS_ORG']
        when nil then [ :sessions, :master ]
        when 'sessions' then [ :sessions ]
        when 'master' then [ :master ]
        else [ :organization ]
      end
      
      databases_to_load.each do |db|
        ActiveRecord::Base.send("connect_to_#{db}")
        file = ENV['SCHEMA'] || "#{Rails.root}/db/schema_#{db}.rb"
        if File.exists?(file)
          load(file)
        else
          abort %{#{file} doesn't exist yet. Run `rake db:migrate` to create it then try again. If you do not intend to use a database, you should instead alter #{Rails.root}/config/application.rb to limit the frameworks that will be loaded}
        end
      end
    end
  end
  
  namespace :test do
    # desc "Recreate the test database from an existent schema.rb file"
    task :load_schema => 'db:test:purge' do
      old_env = Rails.env
      Rails.env = 'test'
      ActiveRecord::Schema.verbose = false
      db_namespace["schema:load"].invoke
      Rails.env = old_env
    end
    
    # desc "Empty the test databases"
    task :purge => [:environment, :load_config] do
      ActiveRecord::Tasks::DatabaseTasks.purge ActiveRecord::Base.configurations['test']
      ActiveRecord::Tasks::DatabaseTasks.purge ActiveRecord::Base.master_configuration('test')
    end
  end
end
