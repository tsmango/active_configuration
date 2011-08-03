require 'active_configuration/error'

module ActiveConfiguration
  
  # Holds a set of configuration details. An instance of this object is created 
  # when the #configure block is used on an ActiveRecord model. For more details 
  # see ActiveRecord::Configuration#configure.
  class Base
    attr_accessor :options
    
    # Initializes an empty options hash to store ActiveConfiguration::Base::Option 
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
    # a new instance of ActiveConfiguration::Base::Option.
    # 
    # @param [Symbol] key the key for this option and settings against this option.
    # @param [Proc] block what should be evaluated against the option.
    def option(key, &block)
      opt = Option.new(key)
      opt.instance_eval(&block)
      @options[key.to_sym] = opt
    end
    
    # Holds the configuration details of a single option. An instance of this 
    # object is created when the #option block is used within a #configure block.
    class Option
      
      # ActiveSupport::Callbacks are included so that the #validate! method can 
      # be automaticalled called after each modification to this option.
      include ActiveSupport::Callbacks
      
      # There is a callback called :validate that should be watched.
      define_callbacks :validate
      
      # After the :validate callback, execute the #validate! method.
      set_callback :validate, :after, :validate!
      set_callback :validate, :after, :validate!
      
      attr_accessor :key, :default_value, :allowed_format, :allowed_values, :allowed_modifiers, :allow_multiple
      
      alias :allow_multiple? :allow_multiple
      
      # Initializes the default values for all deatils of this options. This 
      # includes no default value, no restricted values set, no modifiers, 
      # and a 'string' format.
      # 
      # @param [Symbol] key the key for this option and settings against this option.
      def initialize(key)
        @key               = key
        @default_value     = nil
        @allowed_format    = 'string'
        @allowed_values    = nil
        @allowed_modifiers = nil
        @allow_multiple    = false
      end
      
      # Sets the default value for this option. This cannot be used in 
      # conjunction with the multiple options. Additionally, if a set 
      # of allowed values is set with the #restrict method, this default 
      # value must appear in that list of allowed values.
      # 
      # @param value the value to be used as the default for this option.
      def default(value)
        run_callbacks :validate do
          @default_value = (value.is_a?(Symbol) ? value.to_s : value)
        end
      end
      
      # Sets a specific format that the value of this option must conform 
      # to. Allowed formats include: 'string', 'fixnum', 'float',  'boolean', 
      # 'email', 'url' or a /regular expression/.
      # 
      # @param [String or Regexp] value the format this option must be given in.
      def format(value)
        run_callbacks :validate do
          @allowed_format = (value.is_a?(Symbol) ? value.to_s : value)
        end
      end
      
      # Restricts the allowed values of this option to a given list of values.
      # 
      # Example:
      # 
      #   restrict 'alphabetical', 'manual'
      # 
      # @param [Array] values the allowsed values for this option.
      def restrict(*values)
        run_callbacks :validate do
          @allowed_values = values.collect{|value| (value.is_a?(Symbol) ? value.to_s : value)}
        end
      end
      
      # Restricts the allows modifiers of this option to a given list of modifers.
      # 
      # Example:
      # 
      #   modifiers 'eq', 'lt', 'gt', 'lte', 'gte'
      # 
      # @param [Array] values the allowed modifiers for this option
      def modifiers(*values)
        run_callbacks :validate do
          @allowed_modifiers = values.collect{|value| (value.is_a?(Symbol) ? value.to_s : value)}
        end
      end
      
      # Whether or not this option can have multiple settings set against it.
      # 
      # @param [TrueClass or FalseClass] value either true or false for whether 
      #   this option should allow multiple settings or not.
      def multiple(value)
        run_callbacks :validate do
          @allow_multiple = value
        end
      end
      
      # Validates how the specified configuration options are used with one 
      # another. If an invalid configuration is detected, such as using both 
      # the #default method and setting #multiple to true, an exception of 
      # ActiveConfiguration::Error is raised.
      # 
      # Note: This method is automatically called after each of the 
      # configuration methods are run.
      def validate!
        
        # If both a default value and a list of allowed values are given, 
        # the default value must appear in the list of allowed values.
        if !@default_value.nil? and !@allowed_values.nil? and !@allowed_values.include?(@default_value)
          raise ActiveConfiguration::Error, "The default value '#{@default_value}' isn't present in the list of allowed values."
        end
        
        # If multiple is set, it must be set to either true or false.
        if ![TrueClass, FalseClass].include?(@allow_multiple.class)
          raise ActiveConfiguration::Error, 'The multiple option requires a boolean.'
        end
        
        # If a default value is given, multiple must be false.
        if !@default_value.nil? and @allow_multiple
          raise ActiveConfiguration::Error, 'The default value cannot be set in combination with the multiple option.'
        end
        
        # If a format is specified, it must be an allowed format. This 
        # includes 'string', 'fixnum', 'float', 'boolean', 'email', 'url' 
        # or a /regular exprssion.
        if !@allowed_format.nil? and !['string', 'fixnum', 'float', 'boolean', 'email', 'url'].include?(@allowed_format) and !@allowed_format.is_a?(Regexp)
          raise ActiveConfiguration::Error, "The format #{@allowed_format} is not supported."
        end
      end
    end
  end
end