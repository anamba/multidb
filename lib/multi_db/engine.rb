module MultiDB
  class Engine < Rails::Engine
    engine_name "multidb"
    
    config.app_root = root
    config.autoload_paths += Dir["#{config.root}/lib/**/"]
    
    ActiveSupport.on_load(:active_record) do
      require 'multi_db/active_record_patches'
    end
    
    ActiveSupport.on_load(:action_controller) do
      require 'multi_db/action_controller_patches'
    end
    
    ActiveSupport.on_load(:after_initialize) do
      require 'multi_db/after_initialize_patches'
    end
  end
end

module MultiDB
  class Railtie < Rails::Railtie
    rake_tasks do
      load "multi_db/multidb.rake"
    end
  end
end
