require 'active_configuration/error'

module ActiveConfiguration
  class SettingManger
    attr_accessor :configurable
    
    def initialize(configurable)
      @configurable = configurable
    end
    
    def active_configuration
      @configurable.class.active_configuration
    end
    
    def method_missing(sym, *args, &block)
      if active_configuration.options.has_key?(sym)
        return SettingProxy.new(self, sym)
      else
        return hash.send(sym, *args, &block)
      end
    end
  end
  
  class SettingProxy
    attr_accessor :manager, :key
    
    def initialize(manager, key)
      @manager, @key = manager, key
    end
    
    def option
      return @manager.active_configuration.options[key]
    end
    
    # Read and write non-multiple settings.
    
    def cached_setting
      @cached_setting ||= @manager.configurable.settings.with_key(@key).first
    end
    
    def value
      if option.allow_multiple?
        raise ActiveConfiguration::Error, "For options marked as multiple, call #values rather than #value."
      end
      
      return coerce(cached_setting ? cached_setting.value : option.default_value)
    end
    
    def modifier
      if option.allow_multiple?
        raise ActiveConfiguration::Error, "For options marked as multiple, modifiers are returned in #values rather than with #modifier."
      end
      
      return (cached_setting ? cached_setting.modifier : nil)
    end
    
    def update(value = nil, modifier = nil)
      if option.allow_multiple?
        raise ActiveConfiguration::Error, "For options marked as multiple, call #update_multiple rather than #update."
      end
      
      validate!(value, modifier)
      
      if !(setting = cached_setting)
        setting = @manager.configurable.settings.new(:key => @key)
      end
      
      setting.value    = value
      setting.modifier = modifier if modifier
      
      if setting.save and @cached_setting = @manager.configurable.settings.with_key(@key).all
        return true
      end
      
      return false
    end
    
    # Read and write multiple settings.
    
    def cached_settings
      @cached_settings ||= @manager.configurable.settings.with_key(@key).all
    end
    
    def values
      if !option.allow_multiple?
        raise ActiveConfiguration::Error, "For options not marked as multiple, call #value rather than #values."
      end
      
      return cached_settings.collect{|setting| {:modifier => setting.modifier, :value => coerce(setting.value)}}
    end
    
    def update_multiple(values_with_modifiers = [])
      if !option.allow_multiple?
        raise ActiveConfiguration::Error, "For options not marked as multiple, call #update rather than #update_multiple."
      end
      
      values_with_modifiers.each do |value_with_modifier|
        validate!(value_with_modifier[:value], value_with_modifier[:modifier])
      end
      
      successful_update    = true
      original_setting_ids = @manager.configurable.settings.collect(&:id)
      replaced_setting_ids = []
      
      values_with_modifiers.each do |value_with_modifier|
        if (setting = @manager.configurable.settings.create(:key => @key, :modifier => value_with_modifier[:modifier], :value => value_with_modifier[:value])).new_record?
          successful_update = false && break
        else
          replaced_setting_ids << setting.id
        end
      end
      
      @manager.configurable.settings.reload
      @manager.configurable.settings.where(:id => (successful_update ? original_setting_ids : replaced_setting_ids)).destroy_all
      
      @cached_settings = @manager.configurable.settings.with_key(@key).all
      
      return successful_update
    end
    
    private
    
    def validate!(value = nil, modifier = nil)
      if value.nil?
        raise ActiveConfiguration::Error, 'A value must be given.'
      end
      
      if !option.allowed_values.nil? and !option.allowed_values.include?(value)
        raise ActiveConfiguration::Error, "The default value `#{@default_value}` isn't present in the list of allowed values."
      end
      
      if !option.allowed_format.nil?
        case option.allowed_format
        when 'string'
          if !value.is_a?(String)
            raise ActiveConfiguration::Error, "The value `#{value}` is not a String."
          end
        when 'fixnum'
          if !value.is_a?(Fixnum)
            raise ActiveConfiguration::Error, "The value `#{value}` is not a Fixnum."
          end
        when 'float'
          if !value.is_a?(Float) and !value.is_a?(Fixnum)
            raise ActiveConfiguration::Error, "The value `#{value}` is not a Float."
          end
        when 'email'
          if !value[/^[A-Z0-9_\.%\+\-\']+@(?:[A-Z0-9\-]+\.)+(?:[A-Z]{2,4}|museum|travel)$/i]
            raise ActiveConfiguration::Error, "The value `#{value}` is not an Email Address."
          end
        when 'url'
          if !value[URI.regexp]
            raise ActiveConfiguration::Error, "The value `#{value}` is not a URL."
          end
        end
        
        if option.allowed_format.is_a?(Regexp) and !value[option.allowed_format]
          raise ActiveConfiguration::Error, "The value `#{value}` is not in the correct format."
        end
      end
      
      if !modifier.nil? and !option.allowed_modifiers.nil? and !option.allowed_modifiers.include?(modifier)
        raise ActiveConfiguration::Error, "The modifier `#{modifier}` isn't present in the list of allowed modifiers."
      end
    end
    
    def coerce(value)
      if !value.nil? and !option.allowed_format.nil?
        case option.allowed_format
        when 'fixnum'
          value = value.to_i
        when 'float'
          value = value.to_f
        end
      end
      
      return value
    end
  end
end