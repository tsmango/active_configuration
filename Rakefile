begin
  require 'jeweler'
  require './lib/active_configuration/version'
  
  Jeweler::Tasks.new do |gem|
    gem.name        = 'active_configuration'
    gem.summary     = 'A flexible settings system for Rails 3'
    gem.description = 'A flexible settings system for Rails 3'
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