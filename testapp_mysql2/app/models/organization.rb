class Organization < MultiDB::Organization
  
  def self.create_with_database(org_code = nil, org_name = nil)
    org_code ||= ENV['RAILS_ORG']
    org = new(:name => org_name || org_code, :code => org_code)
    org.save
    
    org.create_database
    org.connect
    
    org
  end
  
end
