require 'active_configuration/engine'
require 'active_configuration/table_name'
require 'active_record/configuration'

ActiveRecord::Base.class_eval do
  include ActiveRecord::Configuration
end