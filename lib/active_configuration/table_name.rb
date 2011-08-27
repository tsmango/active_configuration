module ActiveConfiguration

  # Holds the configuration details of this ActiveConfiguration install.
  class Config

    # Returns the name of the table holding ActiveConfiguration::Settings. This
    # table defaults to `settings` but can be changed with an initializer like:
    #
    #     Rails.configuration.active_configuration_table_name = 'active_configuration_settings'
    #
    # @return [String] the table name holding ActiveConfiguration::Settings.
    def self.table_name
      if Rails.configuration.respond_to?(:active_configuration_table_name)
        return Rails.configuration.active_configuration_table_name
      end

      (Rails.configuration.active_configuration_table_name = 'settings')
    end
  end
end