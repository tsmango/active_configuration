require 'active_configuration/base'
require 'active_configuration/setting_manager'
require 'active_configuration/error'

module ActiveRecord

  # Exposes a #configure method to all ActiveRecord classes and if configured,
  # defines a #settings method for reading and writing settings.
  module Configuration
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods

      # Configures the current ActiveRecord class to allow specific options.
      # After being configured, a #settings method will be defined against
      # all instances as well as a has_many :active_configuration_settings
      # relationship for storing settings.
      #
      # Example configuration:
      #
      #   class Category < ActiveRecord::Base
      #     configure do
      #       option :sort do
      #         default  'alphabetical'
      #         restrict 'alphabetical', 'manual'
      #       end
      #
      #       option :limit do
      #         format 'fixnum'
      #       end
      #
      #       option :price_filter do
      #         format    'float'
      #         modifiers 'eq', 'lt', 'gt', 'lte', 'gte'
      #         multiple  true
      #       end
      #     end
      #   end
      #
      # The #configure block can only contain #option blocks. Within each
      # option block may be a number of methods such as:
      #
      # * default
      #     A default value. Cannot be used in conjunction with multiple.
      #
      # * format -
      #   A specific format, including: 'string', 'fixnum', 'float',
      #   'boolean', 'email', 'url' or a /regular expression/. Defaults
      #   to 'string'.
      #
      # * restrict -
      #   An array of allowed values.
      #
      # * modifiers -
      #   An array of allowed modifiers.
      #
      # * multiple -
      #   Whether or not multiple Settings can be set against the single
      #   option. Must be set to either true or false. Defaults to false.
      #
      #
      # @param [Proc] block the configuration block that contains option blocks.
      def configure(&block)
        class_eval <<-EOV

          # Includes the #settings method for reading and writing settings
          # against any instances of this class.
          include ActiveRecord::Configuration::InstanceMethods

          # Where the actual settings are stored against the instance.
          has_many :active_configuration_settings, :as => :configurable, :class_name => 'ActiveConfiguration::Setting'

          # Returns the configuration details of this class.
          def self.configuration
            @configuration ||= ActiveConfiguration::Base.new
          end
        EOV

        # Evaluates the configuration block given to #configure. Each
        # option block is then evaluated and options are setup. For more
        # details, see ActiveConfiguration::Base.
        configuration.instance_eval(&block)
      end
    end

    module InstanceMethods

      # Returns an ActiveConfiguration::SettingManager that proxies
      # all reads and writes of settings to ActiveConfiguration::SettingProxy
      # objects for the specific setting requested.
      def settings
        @setting_manager ||= ActiveConfiguration::SettingManager.new(self)
      end
    end
  end
end