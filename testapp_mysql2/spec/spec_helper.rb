ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)

require 'rspec/rails'
require 'rspec/autorun'
require 'simplecov'
require 'factory_girl_rails'

Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }

RSpec.configure do |config|
  config.order = "random"
  
  config.before(:suite) do
    Organization.create_with_database('test', 'Developer Test Practice') unless Organization.find_by_code('test')
  end
  
  config.before(:each) do
    Organization.first.connect
  end
  
  config.after(:suite) do
  end
end
