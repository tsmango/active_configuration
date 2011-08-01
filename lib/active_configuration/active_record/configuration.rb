require 'active_configuration/base'
require 'active_configuration/setting_manager'
require 'active_configuration/error'

module ActiveRecord
  module Configuration
    def self.included(base)
      base.extend(ClassMethods)
    end
    
    module ClassMethods
      def configure(&block)
        class_eval <<-EOV
          include ActiveRecord::Configuration::InstanceMethods
          
          has_many :active_configuration_settings, :as => :configurable, :class_name => 'ActiveConfiguration::Setting'
          
          def self.configuration
            @configuration ||= ActiveConfiguration::Base.new
          end
        EOV
        
        configuration.instance_eval(&block)
      end
    end
    
    module InstanceMethods
      def settings
        @setting_manager ||= ActiveConfiguration::SettingManager.new(self)
      end
    end
  end
end