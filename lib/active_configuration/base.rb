module ActiveConfiguration
  class Base
    attr_accessor :options
    
    def initialize
      @options = []
    end
    
    def option(key, &block)
      opt = Option.new(key)
      opt.instance_eval(&block)
      @options << opt
    end
    
    class Option
      include ActiveSupport::Callbacks
      
      define_callbacks :validate
      set_callback     :validate, :after, :validate!
      set_callback     :validate, :after, :validate!
      
      attr_accessor :key, :default_value, :allowed_format, :allowed_values, :allowed_modifiers, :allow_multiple
      
      def initialize(key)
        @key               = key
        @default_value     = nil
        @allowed_format    = nil
        @allowed_values    = nil
        @allowed_modifiers = nil
        @allow_multiple    = false
      end
      
      def default(value)
        run_callbacks :validate do
          @default_value = value
        end
      end
      
      def format(value)
        run_callbacks :validate do
          @allowed_format = value
        end
      end
      
      def restrict(*values)
        run_callbacks :validate do
          @allowed_values = values
        end
      end
      
      def modifiers(*values)
        run_callbacks :validate do
          @allowed_modifiers = values
        end
      end
      
      def multiple(value)
        run_callbacks :validate do
          @allow_multiple = value
        end
      end
      
      def validate!
        if !@default_value.nil? and !@allowed_values.nil? and !@allowed_values.include?(@default_value)
          raise ActiveConfiguration::Error, "The default value `#{@default_value}` isn't present in the list of allowed values."
        end
        
        if ![TrueClass, FalseClass].include?(@allow_multiple.class)
          raise ActiveConfiguration::Error, 'The multiple option requires a boolean.'
        end
      end
    end
  end
  
  class Error < RuntimeError; end
end