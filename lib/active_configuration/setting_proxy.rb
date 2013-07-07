require 'active_configuration/error'

module ActiveConfiguration

  # Handles the reading and writing of ActiveConfiguration::Setting objects
  # and ensures configuration requirements are upheld.
  class SettingProxy
    attr_accessor :manager
    attr_accessor :key
    attr_accessor :value

    # Initializes a new ActiveConfiguration::SettingProxy with a related
    # SettingManager and a key for this setting. This setting's modifiers
    # and values are cached locally as either a Hash or an Array for later
    # access and manipulation.
    #
    # @param [ActiveConfiguration::SettingManager] manager the manager which
    #   holds this SettingProxy and has access to the configurable object that
    #   this setting will be attached to.
    # @param [Symbol] key the key for this setting and its related option.
    def initialize(manager, key)
      @manager, @key = manager, key

      if settings = @manager.configurable.active_configuration_settings.with_key(@key).to_a
        if option.allow_multiple?
          @value = settings.collect{|setting| {:value => coerce(setting.value), :modifier => setting.modifier}}

        else
          setting = settings.first

          @value = {
            :modifier => (setting ? setting.modifier : nil),
            :value    => coerce(setting ? setting.value : option.default_value)
          }
        end
      end
    end

    # Replaces the underlying Hash or Array with a replacement. This handles
    # reverting to defaults when nil is given as the value.
    #
    # Note: Athough Hashes given may contain keys other than :modifier and
    # :value, all other keys will be stripped out and not saved.
    #
    # @raise [ArgumentError] if a Hash, Array or NilClass isn't given for a
    #   multiple option.
    # @raise [ArgumentError] if a Hash or NilClass isn't given for a non-multiple
    #   option.
    #
    # @param [Hash] value_with_modifier the Hash or Array of Hashes containing
    #   modifier and value pairs.
    #
    # @return [Hash, Array] the requested change.
    def replace(value_with_modifier)
      if option.allow_multiple?
        if value_with_modifier.is_a?(Hash) or value_with_modifier.is_a?(Array) or value_with_modifier.is_a?(NilClass)
          value_with_modifier = [value_with_modifier].flatten.collect{|value_with_modifier| {:modifier => nil, :value => nil}.merge(value_with_modifier.nil? ? {} : value_with_modifier.slice(*[:modifier, :value]))}
          value_with_modifier.delete({:modifier => nil, :value => nil})
        else
          raise ArgumentError, "Array expected."
        end
      else
        if value_with_modifier.is_a?(Hash) or value_with_modifier.is_a?(NilClass)
          value_with_modifier = {:modifier => nil, :value => nil}.merge(value_with_modifier.nil? ? {:value => coerce(option.default_value)} : value_with_modifier.slice(*[:modifier, :value]))
        else
          raise ArgumentError, "Hash expected."
        end
      end

      return (@value = value_with_modifier)
    end

    # Checks modifiers and values on this setting for validation errors and, if
    # found, adds those errors to this proxy's model's collection of errors.
    def validate
      errors = Array.new

      [value].flatten.each do |value_with_modifier|
        value    = value_with_modifier[:value]
        modifier = value_with_modifier[:modifier]

        if !option.allowed_values.nil? and !option.allowed_values.include?(value)
          errors << "The value '#{value}' for the '#{option.key}' setting isn't present in the list of allowed values."
        end

        if !option.allowed_format.nil?
          case option.allowed_format
          when 'string'
            if !value.is_a?(String)
              errors << "The value '#{value}' for the '#{option.key}' setting is not a String."
            end
          when 'fixnum'
            if !value.is_a?(Fixnum)
              errors << "The value '#{value}' for the '#{option.key}' setting is not a Fixnum."
            end
          when 'float'
            if !value.is_a?(Float) and !value.is_a?(Fixnum)
              errors << "The value '#{value}' for the '#{option.key}' setting is not a Float."
            end
          when 'boolean'
            if !value.is_a?(TrueClass) and !value.is_a?(FalseClass)
              errors << "The value '#{value}' for the '#{option.key}' setting is not a Boolean."
            end
          when 'email'
            if !value[/^[A-Z0-9_\.%\+\-\']+@(?:[A-Z0-9\-]+\.)+(?:[A-Z]{2,4}|museum|travel)$/i]
              errors << "The value '#{value}' for the '#{option.key}' setting is not an Email Address."
            end
          when 'url'
            if !value[URI.regexp]
              errors << "The value '#{value}' for the '#{option.key}' setting is not a URL."
            end
          end

          if option.allowed_format.is_a?(Regexp) and !value[option.allowed_format]
            errors << "The value '#{value}' for the '#{option.key}' setting is not in the correct format."
          end
        end

        if !modifier.nil? and !option.allowed_modifiers.nil? and !option.allowed_modifiers.include?(modifier)
          errors << "The modifier '#{modifier}' for the '#{option.key}' setting isn't present in the list of allowed modifiers."
        end
      end

      errors.each do |error|
        @manager.configurable.errors.add(:settings, error)
      end
    end

    # Saves this setting's modifiers and values.
    #
    # @return [Boolean] whether or not the save was successful.
    def save
      save_status = true
      original_setting_ids = @manager.configurable.active_configuration_settings.with_key(@key).collect(&:id)
      replaced_setting_ids = []

      [value].flatten.each do |value_with_modifier|
        if (setting = @manager.configurable.active_configuration_settings.create(:key => @key, :modifier => value_with_modifier[:modifier], :value => value_with_modifier[:value])).new_record?
          save_status = false && break
        else
          replaced_setting_ids << setting.id
        end
      end

      @manager.configurable.active_configuration_settings.reload
      @manager.configurable.active_configuration_settings.with_key(@key).where(:id => (save_status ? original_setting_ids : replaced_setting_ids)).destroy_all

      @manager.settings.delete(@key)

      return save_status
    end

    # Returns the Hash or Array representation of the underlying stored settings 
    # depending on whether or not this is a multiple option.
    # 
    # @return [Hash] the value and modifier, as a Hash, for a non-multiple
    #   option.
    # @return [Array] the array of hashes containing value and modifiers, like
    #   those returned on a non-multiple options, for a multiple option.
    def inspect
      return @value.inspect
    end

    private

    # Returns this SettingProxy's related Option based on the given key. This
    # is necessary to ensure all configuration requirements are upheld during
    # reads and writes.
    #
    # @return [ActiveConfiguration::Option] the option for this setting.
    def option
      return @manager.configurable.class.configuration.options[key]
    end

    # Coerces a stored String value into the expected type if an allowed format
    # is explicitly set on this setting's option.
    #
    # Note: Because values are validated against given formats when updated,
    # it is assumed that they can be properly coerced back to their intended
    # type.
    #
    # @param [String] value the value stored in the database that must be coerced.
    #
    # @return [String, Fixnum, Float, TrueClass, FalseClass] the properly coerced
    #   value, assuming the value should be coerced.
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