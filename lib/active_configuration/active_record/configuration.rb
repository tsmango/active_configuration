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
          
          has_many :settings, :as => :configurable, :class_name => 'ActiveConfiguration::Setting'
        EOV
        
        class << self
          define_method :active_configuration do
            @active_configuration ||= ActiveConfiguration::Base.new
          end
        end
        
        active_configuration.instance_eval(&block)
      end
    end
    
    module InstanceMethods
      def setting
        @setting_manager ||= ActiveConfiguration::SettingManger.new(self)
      end
    end
  end
end