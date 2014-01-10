module MultiDB
  if defined?(Rails)
    require 'multi_db/engine'
  else
    # hmm... haven't tested this case
    require 'multi_db/active_record_patches'
    # require 'multidb/organization'
    # require 'multidb/organization_host'
  end
end
