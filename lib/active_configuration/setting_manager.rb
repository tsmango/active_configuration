require 'active_configuration/setting_proxy'

module ActiveConfiguration
  
  # Returns a SettingProxy object for any option that has been configured.
  class SettingManager
    attr_accessor :configurable
    
    # Initializes this SettingManager and keeps track of what model this 
    # SettingManager is proxying settings for.
    # 
    # @param [ActiveRecord::Base] configurable the model that hsa been 
    #   configured for use with ActiveConfiguration.
    def initialize(configurable)
      @configurable = configurable
    end
    
    # Returns a SettingProxy object for any requested option that exists.
    # 
    # Note: Because SettingManager is returned from a model's #settings 
    # method, any option name chained off of #settings will pass through 
    # this #method_missing method. If the option exists with that name, 
    # a SettingProxy object for that option is returned.
    # 
    # @return [SettingProxy] SettingProxy a new SettingProxy for the 
    #   specified option.
    def method_missing(sym, *args, &block)
      if @configurable.class.configuration.options.has_key?(sym)
        return SettingProxy.new(self, sym)
      else
        return hash.send(sym, *args, &block)
      end
    end
    
    # If this SettingManager responds with a SettingProxy from #method_missing 
    # when called with an appropriate option, #respond_to? will return true.
    def respond_to?(method, include_private = false)
      return (@configurable.class.configuration.options.has_key?(method.to_sym) || super)
    end
  end
end