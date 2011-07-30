require 'active_configuration/setting_proxy'

module ActiveConfiguration
  class SettingManger
    attr_accessor :configurable
    
    def initialize(configurable)
      @configurable = configurable
    end
    
    def configuration
      @configurable.class.configuration
    end
    
    def method_missing(sym, *args, &block)
      if configuration.options.has_key?(sym)
        return SettingProxy.new(self, sym)
      else
        return hash.send(sym, *args, &block)
      end
    end
  end
end