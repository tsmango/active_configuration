require 'active_configuration/error'

module ActiveConfiguration
  class SettingProxy
    attr_accessor :manager, :key
    
    def initialize(manager, key)
      @manager, @key = manager, key
    end
    
    def [](attribute)
      if option.allow_multiple?
        raise NoMethodError, "undefined method `[]' for #{self.inspect}:#{self.class.name}"
      end
      
      case attribute.to_sym
      when :modifier: (cached_setting ? cached_setting.modifier : nil)
      when :value:    coerce(cached_setting ? cached_setting.value : option.default_value)
      else nil
      end
    end
    
    def to_a
      if !option.allow_multiple?
        raise NoMethodError, "undefined method `size' for #{self.inspect}:#{self.class.name}"
      end
      
      return values
    end
    
    def collect(&block)
      if !option.allow_multiple?
        raise NoMethodError, "undefined method `size' for #{self.inspect}:#{self.class.name}"
      end
      
      return values.collect(&block)
    end
    
    def each(&block)
      if !option.allow_multiple?
        raise NoMethodError, "undefined method `size' for #{self.inspect}:#{self.class.name}"
      end
      
      return values.each(&block)
    end
    
    def each_with_index(&block)
      if !option.allow_multiple?
        raise NoMethodError, "undefined method `size' for #{self.inspect}:#{self.class.name}"
      end
      
      return values.each_with_index(&block)
    end
    
    def size
      if !option.allow_multiple?
        raise NoMethodError, "undefined method `size' for #{self.inspect}:#{self.class.name}"
      end
      
      return values.size
    end
    
    def update(*values_with_modifiers)
      if values_with_modifiers.size > 1 and !option.allow_multiple?
        raise ActiveConfiguration::Error, "For options not marked as multiple, you may not have multiple settings."
      end
      
      values_with_modifiers.each do |value_with_modifier|
        validate!(value_with_modifier[:value], value_with_modifier[:modifier])
      end
      
      successful_update    = true
      original_setting_ids = @manager.configurable.active_configuration_settings.with_key(@key).collect(&:id)
      replaced_setting_ids = []
      
      values_with_modifiers.each do |value_with_modifier|
        if (setting = @manager.configurable.active_configuration_settings.create(:key => @key, :modifier => value_with_modifier[:modifier], :value => value_with_modifier[:value])).new_record?
          successful_update = false && break
        else
          replaced_setting_ids << setting.id
        end
      end
      
      @manager.configurable.active_configuration_settings.reload
      @manager.configurable.active_configuration_settings.with_key(@key).where(:id => (successful_update ? original_setting_ids : replaced_setting_ids)).destroy_all
      
      @cached_settings = @manager.configurable.active_configuration_settings.with_key(@key).all
      
      return successful_update
    end
    
    def inspect
      if option.allow_multiple?
        return cached_settings.collect{|setting| {:modifier => setting.modifier, :value => coerce(setting.value)}}.inspect
      elsif cached_setting
        return {:modifier => cached_setting.modifier, :value => coerce(cached_setting.value)}.inspect
      else
        return {:modifier => nil, :value => coerce(option.default_value)}.inspect
      end
    end
    
    private
    
    def option
      return @manager.configurable.class.configuration.options[key]
    end
    
    def cached_setting
      cached_settings.first
    end
    
    def cached_settings
      @cached_settings ||= @manager.configurable.active_configuration_settings.with_key(@key).all
    end
    
    def values
      return cached_settings.collect{|setting| {:modifier => setting.modifier, :value => coerce(setting.value)}}
    end
    
    def validate!(value = nil, modifier = nil)
      if value.nil?
        raise ActiveConfiguration::Error, 'A value must be given like :value => value.'
      end
      
      if !option.allowed_values.nil? and !option.allowed_values.include?(value)
        raise ActiveConfiguration::Error, "The default value '#{@default_value}' isn't present in the list of allowed values."
      end
      
      if !option.allowed_format.nil?
        case option.allowed_format
        when 'string'
          if !value.is_a?(String)
            raise ActiveConfiguration::Error, "The value '#{value}' is not a String."
          end
        when 'fixnum'
          if !value.is_a?(Fixnum)
            raise ActiveConfiguration::Error, "The value '#{value}' is not a Fixnum."
          end
        when 'float'
          if !value.is_a?(Float) and !value.is_a?(Fixnum)
            raise ActiveConfiguration::Error, "The value '#{value}' is not a Float."
          end
        when 'boolean'
          if !value.is_a?(TrueClass) and !value.is_a?(FalseClass)
            raise ActiveConfiguration::Error, "The value '#{value}' is not a Boolean."
          end
        when 'email'
          if !value[/^[A-Z0-9_\.%\+\-\']+@(?:[A-Z0-9\-]+\.)+(?:[A-Z]{2,4}|museum|travel)$/i]
            raise ActiveConfiguration::Error, "The value '#{value}' is not an Email Address."
          end
        when 'url'
          if !value[URI.regexp]
            raise ActiveConfiguration::Error, "The value '#{value}' is not a URL."
          end
        end
        
        if option.allowed_format.is_a?(Regexp) and !value[option.allowed_format]
          raise ActiveConfiguration::Error, "The value '#{value}' is not in the correct format."
        end
      end
      
      if !modifier.nil? and !option.allowed_modifiers.nil? and !option.allowed_modifiers.include?(modifier)
        raise ActiveConfiguration::Error, "The modifier '#{modifier}' isn't present in the list of allowed modifiers."
      end
    end
    
    def coerce(value)
      if !value.nil? and !option.allowed_format.nil?
        case option.allowed_format
        when 'fixnum'
          value = value.to_i
        when 'float'
          value = value.to_f
        when 'boolean'
          value = true  if (value == 'true'  or value == 't')
          value = false if (value == 'false' or value == 'f')
        end
      end
      
      return value
    end
  end
end