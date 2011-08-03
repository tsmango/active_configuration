require 'active_configuration/option'

module ActiveConfiguration
  
  # Holds a set of configuration details. An instance of this object is created 
  # when the #configure block is used on an ActiveRecord model. For more details 
  # see ActiveRecord::Configuration#configure.
  class Base
    attr_accessor :options
    
    # Initializes an empty options hash to store ActiveConfiguration::Option 
    # instances containing configuration details.
    def initialize
      @options = HashWithIndifferentAccess.new
    end
    
    # Creates and accepts the configuration details for an Option.
    # 
    # An example of setting an option with a block:
    # 
    #   option :sort do
    #     default  'alphabetical'
    #     restrict 'alphabetical', 'manual'
    #   end
    # 
    # Here, the #option method is called and passed the key of :sort and then the 
    # the block that follows. The block given to #option is then evaluated against 
    # a new instance of ActiveConfiguration::Option.
    # 
    # @param [Symbol] key the key for this option and settings against this option.
    # @param [Proc] block what should be evaluated against the option.
    def option(key, &block)
      opt = Option.new(key)
      opt.instance_eval(&block)
      @options[key.to_sym] = opt
    end
  end
end