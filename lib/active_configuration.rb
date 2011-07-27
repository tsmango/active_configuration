require 'active_configuration/engine'
require 'active_configuration/active_record/configuration'

ActiveRecord::Base.class_eval do
  include ActiveRecord::Configuration
end