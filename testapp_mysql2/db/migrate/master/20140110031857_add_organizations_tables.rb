class AddOrganizationsTables < ActiveRecord::Migration
  
  def change
    create_table :organization_hosts do |t|
      t.integer  :organization_id, :null => false
      t.string   :host,            :null => false
      t.datetime :created_at,      :null => false
      t.datetime :updated_at,      :null => false
    end
    add_index :organization_hosts, [:host], :unique => true
    
    create_table :organizations do |t|
      t.string   :name
      t.string   :code,                         :null => false
      t.boolean  :active,     :default => true, :null => false
      t.datetime :created_at,                   :null => false
      t.datetime :updated_at,                   :null => false
    end
    add_index :organizations, [:code], :unique => true
  end
  
end
