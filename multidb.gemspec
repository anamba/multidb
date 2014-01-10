# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "multidb"
  s.version     = '3.2.0'
  s.platform    = Gem::Platform::RUBY
  s.author      = "Aaron Namba"
  s.email       = "aaron@biggerbird.com"
  s.homepage    = "https://github.com/anamba/imagine_cms"
  s.summary     = %q{MultiDB for ActiveRecord}
  s.description = %q{Enables multitenant setup with one database per tenant. See README for details.}
  
  s.required_ruby_version     = '>= 1.9.3'
  s.required_rubygems_version = '>= 1.8.11'
  
  s.license = 'MIT'
  
  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  
  s.add_dependency "activerecord", "~> 3.2.0"
end
