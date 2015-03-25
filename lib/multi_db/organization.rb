module MultiDB
  class Organization < ActiveRecord::Base
    connect_to_master
    
    has_many :hosts, class_name: 'OrganizationHost', inverse_of: :organization, dependent: :destroy
    
    validates :code, presence: true, uniqueness: true
    before_validation :ensure_code, on: :create
    
    scope :active, -> { where(active: true) }
    
    def ensure_code
      return true if name.blank?  # let the validation process continue if there's no name yet
      
      self.code = name.downcase.gsub(/[^-\w\d]+/, '-') if code.blank?
      
      i, base_code = 1, code
      while self.class.where(code: code).count > 0
        i += 1
        self.code = "#{base_code}#{i}"
      end
    end
    
    def connect(set_env = false)
      ActiveRecord::Base.connect_to_organization(self, set_env)
    end
    
    def create_database
      if code =~ /^[-\w\d]+$/
        begin
          ActiveRecord::Base.connection.create_database("#{ActiveRecord::Base.configurations[Rails.env]['database']}_#{code}")
        rescue Exception => e
          if e.message =~ /Can't create database '(.*?)'; database exists/
            puts "Warning: database #{$1} already exists"
          else
            throw e
          end
        end
        
        connect
        
        ActiveRecord::Migration.suppress_messages do
          load "#{Rails.root}/db/schema_organization.rb"
        end
      end
    end
    
    def drop_database!
      if Rails.env.production?
        raise "Won't drop database in production mode for safety reasons."
      else
        if code =~ /^[-\w\d]+$/
          # watch for sql injection here
          ActiveRecord::Base.connection.drop_database("#{ActiveRecord::Base.configurations[Rails.env]['database']}_#{code}")
        end
      end
    end
  end
end
