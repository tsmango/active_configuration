require 'active_configuration/setting_proxy'

module ActiveConfiguration

  # Returns a SettingProxy object for any option that has been configured.
  class SettingManager
    attr_accessor :configurable
    attr_accessor :settings

    # Initializes this SettingManager and keeps track of what model this
    # SettingManager is proxying settings for.
    #
    # @param [ActiveRecord::Base] configurable the model that hsa been
    #   configured for use with ActiveConfiguration.
    def initialize(configurable)
      @configurable = configurable
      @settings     = Hash.new
    end

    # Provides access to setting details for a setting at the given key.
    #
    # @param [Symbol] key the key of the requested setting.
    #
    # @return [Hash, Array, NilClass] the Hash or Array of Hashes for the
    #   setting with the given key or nil if there isn't a match.
    def [](key)
      if @configurable.class.configuration.options.has_key?(key)
        @settings[key] ||= SettingProxy.new(self, key)

        return @settings[key].value
      end

      return nil
    end

    # Replaces the Hash or Array of Hashes for the setting with the given
    # key with the given value.
    #
    # @param [Symbol] key the key of the requested setting.
    #
    # @return [Hash, Array, NilClass] the Hash or Array of Hashes for the
    #   setting with the given key or nil if there isn't a match.
    def []=(key, value)
      if @configurable.class.configuration.options.has_key?(key)
        @settings[key] ||= SettingProxy.new(self, key)
        @settings[key].replace(value)

        return @settings[key].value
      end

      return nil
    end

    # Writes over multiple settings at once.
    #
    # @param [Hash] replacement_settings the has of settings to be set.
    def write_settings(replacement_settings = {})
      replacement_settings.each_pair do |key, value|
        self[key] = value
      end
    end

    # Runs validations against all settings with pending modificaitons.
    # Any errors are added to @configurable.errors[:settings].
    def validate
      settings.values.collect{|setting| setting.validate}
    end

    # Saves all settings with pending modificaitons.
    #
    # @return [Boolean] whether or not the save was successful.
    def save
      return !settings.values.collect{|setting| setting.save}.include?(false)
    end

    # Writes over multiple settings and saves all setting updates at once.
    #
    # @param [Hash] replacement_settings the has of settings to be set.
    #
    # @return [Boolean] whether or not the save was successful.
    def update_settings(replacement_settings = {})
      write_settings(replacement_settings)

      validate

      return (@configurable.errors[:settings].empty? ? save : false)
    end

    # Resets any pending setting modifications.
    def reload
      @settings = Hash.new
    end
  end
end