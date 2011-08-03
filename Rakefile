begin
  require 'jeweler'
  require './lib/active_configuration/version'
  
  Jeweler::Tasks.new do |gem|
    gem.name        = 'active_configuration'
    
    gem.summary     = "A flexible settings store for Rails 3.x ActiveRecord models."
    gem.description = "ActiveConfiguration is a Rails 3.x engine for reading and writing settings, 
                       in a flexible manner, against ActiveRecord models. This engine is meant to 
                       be used with a highly configurable application so that you don't necessarily 
                       need to setup specific columns and tables for handling similar style 
                       configurations."
    
    gem.email       = 'tsmango@gmail.com'
    gem.authors     = ['Thomas Mango']
    gem.homepage    = 'http://github.com/tsmango/active_configuration'
    gem.files       = Dir["{lib}/**/*", "{app}/**/*", "{config}/**/*"]
    gem.version     = ActiveConfiguration::Version::STRING
    
    gem.add_dependency 'activerecord',  '>= 3.0.0'
    gem.add_dependency 'activesupport', '>= 3.0.0'
  end
  
rescue
  puts "There was a problem loading Jeweler."
end