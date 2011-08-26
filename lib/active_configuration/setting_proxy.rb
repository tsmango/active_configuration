require 'active_configuration/error'

module ActiveConfiguration

  # Handles the reading and writing of ActiveConfiguration::Setting objects
  # and ensures configuration requirements are upheld.
  class SettingProxy
    attr_accessor :manager, :key

    # Initializes a new ActiveConfiguration::SettingProxy with a related
    # SettingManager and a key for this setting.
    #
    # @param [ActiveConfiguration::SettingManager] manager the manager which
    #   holds this SettingProxy and has access to the configurable object that
    #   this setting will be attached to.
    # @param [Symbol] key the key for this setting and its related option.
    def initialize(manager, key)
      @manager, @key = manager, key
    end

    # Gives access to a non-multiple option's value and modifier. If a value
    # isn't explicitly set for this option and a default value is, the default
    # value is returned.
    #
    # Note: This method may not be used for a multiple option.
    #
    # @param [Symbol] attribute either :value or :modifier depending on what
    #   should be returned.
    #
    # @raise [ActiveConfiguration::Error] if this is a multiple option.
    #
    # @return [String, Fixnum, Float, TrueClass, FalseClass] the value or
    #   modifier requested. If the value is requested and a specific format
    #   is defined for this setting's option, the stored String will be coerced
    #   into the correct type.
    #
    # @see #coerce
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

    # Returns an Array of hashes containing all {:modifier, :value} pairs for
    # all settings on this multiple option setting.
    #
    # Note: This method may not be used for a non-multiple option.
    #
    # @raise [ActiveConfiguration::Error] if this is a non-multiple option.
    #
    # @return [Array] the Array of modifiers and values set for this setting.
    def to_a
      if !option.allow_multiple?
        raise NoMethodError, "undefined method `size' for #{self.inspect}:#{self.class.name}"
      end

      return cached_settings.collect{|setting| {:modifier => setting.modifier, :value => coerce(setting.value)}}
    end

    # Acts like Array#collect by passing a given block into the #collect method
    # of the array representation of this setting.
    #
    # Note: This method may not be used for a non-multiple option.
    #
    # @param [Proc] block the block that should be passed to the array of
    #   settings' #collect method.
    #
    # @raise [ActiveConfiguration::Error] if this is a non-multiple option.
    #
    # @return [Array] the Array result of the given block against this
    #   array of settings.
    def collect(&block)
      if !option.allow_multiple?
        raise NoMethodError, "undefined method `size' for #{self.inspect}:#{self.class.name}"
      end

      return to_a.collect(&block)
    end

    # Acts like Array#each by passing a given block into the #each method
    # of the array representation of this setting.
    #
    # Note: This method may not be used for a non-multiple option.
    #
    # @param [Proc] block the block that should be passed to the array of
    #   settings' #each method.
    #
    # @raise [ActiveConfiguration::Error] if this is a non-multiple option.
    #
    # @return [Array] the Array of modifiers and values set for this setting.
    def each(&block)
      if !option.allow_multiple?
        raise NoMethodError, "undefined method `size' for #{self.inspect}:#{self.class.name}"
      end

      return to_a.each(&block)
    end

    # Acts like Array#each_with_index by passing a given block into the
    # #each_with_index method of the array representation of this setting.
    #
    # Note: This method may not be used for a non-multiple option.
    #
    # @param [Proc] block the block that should be passed to the array of
    #   settings' #each_with_index method.
    #
    # @raise [ActiveConfiguration::Error] if this is a non-multiple option.
    #
    # @return [Array] the Array of modifiers and values set for this setting.
    def each_with_index(&block)
      if !option.allow_multiple?
        raise NoMethodError, "undefined method `size' for #{self.inspect}:#{self.class.name}"
      end

      return to_a.each_with_index(&block)
    end

    # Returns the number of settings set against this option.
    #
    # Note: This method may not be used for a non-multiple option.
    #
    # @raise [ActiveConfiguration::Error] if this is a non-multiple option.
    #
    # @return [Fixnum] the number of settings set against this option.
    def size
      if !option.allow_multiple?
        raise NoMethodError, "undefined method `size' for #{self.inspect}:#{self.class.name}"
      end

      return to_a.size
    end

    # Takes a single Hash with a value and modifier or an Array of Hashes,
    # depending on whether or not this is a multiple option, and updates
    # the underlying ActiveConfiguration::Setting records in the database.
    #
    # This method, unlike #update!, will catch any errors and add messages
    # to the containing object's set of #errors. If you use this method to
    # update settings, be sure to check your model's #errors method.
    #
    # @param [Hash, Array] values_with_modifiers the single Hash or Array
    #   of Hashes with the values and modifiers to set. An example single
    #   Hash would be {:modifier => 'lt', :value => 10.00}. An Array of
    #   Hashes may be used for multiple options.
    #
    # @return [TrueClass, FalseClass] whether or not the update was a success.
    #   Note: If any errors are raised during the update, error messages will
    #   be added to this setting's containing model's set of #errors.
    #
    # @see #validate!
    def update(*values_with_modifiers)
      update!(*values_with_modifiers)

    rescue ActiveConfiguration::Error => error
      @manager.configurable.errors.add(:settings, error.message)

      return false
    end

    # Takes a single Hash with a value and modifier or an Array of Hashes,
    # depending on whether or not this is a multiple option, and updates
    # the underlying ActiveConfiguration::Setting records in the database.
    #
    # This method, unlike #update, will not catch any errors or add messages
    # to the containing object's set of #errors. If you use this method to
    # update settings, be sure to rescue ActiveConfiguration::Error.
    #
    # @param [Hash, Array] values_with_modifiers the single Hash or Array
    #   of Hashes with the values and modifiers to set. An example single
    #   Hash would be {:modifier => 'lt', :value => 10.00}. An Array of
    #   Hashes may be used for multiple options.
    #
    # @raise [ActiveConfiguration::Error] if an Array of hashes is given
    #   but this is a non-multiple option.
    # @raise [ActiveConfiguration::Error] if a validation error occurs while
    #   processing any of the values or modifiers.
    #
    # @return [TrueClass, FalseClass] whether or not the update was a success.\
    #
    # @see #validate!
    def update!(*values_with_modifiers)
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

    # Returns an Array of Hash object respresentation or a single Hash
    # object representation depending on whether or not this is a
    # multiple option or not.
    #
    # Examples:
    #
    #   ?> category.settings.sort
    #   => {:value=>"alphabetical", :modifier=>nil}
    #
    #   ?> category.settings.price_filter
    #   => [{:value=>10.0, :modifier=>"gt"}, {:value=>25.0, :modifier=>"lte"}]
    #
    # @return [Hash] the value and modifier, as a Hash, for a non-multiple
    #   option.
    # @return [Array] the array of hashes containing value and modifiers, like
    #   those returned on a non-multiple options, for a multiple option.
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

    # Returns this SettingProxy's related Option based on the given key. This
    # is necessary to ensure all configuration requirements are upheld during
    # reads and writes.
    #
    # @return [ActiveConfiguration::Option] the option for this setting.
    def option
      return @manager.configurable.class.configuration.options[key]
    end

    # Returns the single cached ActiveConfiguration::Setting object for this
    # SettingProxy.
    #
    # Note: This is only used for non-multiple options.
    #
    # @todo Add support for an intermediary caching layer, such as Memecached
    #   or Redis, so that settings don't always have to be laoded directly
    #   from the database.
    #
    # @return [ActiveConfiguration::Setting] the setting object for this proxy.
    def cached_setting
      cached_settings.first
    end

    # Returns an array of cached ActiveConfiguration::Setting objects for this
    # SettingProxy.
    #
    # Note: This is only used for multiple options.
    #
    # @todo Add support for an intermediary caching layer, such as Memecached
    #   or Redis, so that settings don't always have to be laoded directly
    #   from the database.
    #
    # @return [Array] an array of ActiveConfiguration::Setting objects for
    #   this proxy.
    def cached_settings
      @cached_settings ||= @manager.configurable.active_configuration_settings.with_key(@key).all
    end

    # Validates a given value and modifier to ensure it abides by all
    # configuration details set on this setting's option.
    #
    # @param [String, Fixnum, Float, TrueClass, FalseClass] value the
    #   value that needs to be validated.
    # @param [String] modifier the modifier that needs to be validated.
    #
    # @raise [ActiveConfiguration::Error] if a value isn't given.
    # @raise [ActiveConfiguration::Error] if a list of allowed values
    #   is specified but the given value does not appear in that list.
    # @raise [ActiveConfiguration::Error] if an allowed format is
    #   specified but the given value does not conform to that format.
    # @raise [ActiveConfiguration::Error] if a list of allowed modifiers
    #   is specified but the given modifier does not appear in that list.
    def validate!(value = nil, modifier = nil)
      if value.nil?
        raise ActiveConfiguration::Error, 'A value must be given like :value => value.'
      end

      if !option.allowed_values.nil? and !option.allowed_values.include?(value)
        raise ActiveConfiguration::Error, "The value '#{value}' isn't present in the list of allowed values."
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