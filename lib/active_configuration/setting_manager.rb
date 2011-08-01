require 'active_configuration/setting_proxy'

module ActiveConfiguration
  class SettingManager
    attr_accessor :configurable
    
    def initialize(configurable)
      @configurable = configurable
    end
    
    def method_missing(sym, *args, &block)
      if @configurable.class.configuration.options.has_key?(sym)
        return SettingProxy.new(self, sym)
      else
        return hash.send(sym, *args, &block)
      end
    end
    
    def respond_to?(method, include_private = false)
      return (@configurable.class.configuration.options.has_key?(method.to_sym) || super)
    end
  end
end