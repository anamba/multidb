module MultiDB
  class OrganizationHost < ActiveRecord::Base
    connect_to_master
    
    belongs_to :organization, :inverse_of => :hosts
  end
end
