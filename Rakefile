begin
  require 'jeweler'
  require './lib/active_configuration/version'
  
  Jeweler::Tasks.new do |gem|
    gem.name        = 'active_configuration'
    
    gem.summary     = "A generic settings store for Rails 3.x ActiveRecord models."
    
    gem.description = "ActiveConfiguration is an engine that exposes a generic settings store to 
                       ActiveRecord models. Made for very configurable applications, it allows you 
                       to avoid implementing specific ways to store settings for each model that 
                       needs such configuration. If your application isn't very configurable, 
                       ActiveConfiguration is probably overkill."
    
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