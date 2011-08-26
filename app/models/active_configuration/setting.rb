module ActiveConfiguration

  # Holds the details of a Setting and is attached to any model configured
  # for use with ActiveConfiguration.
  #
  # Note: Settings are not meant to be created and updated directly.
  # Rather, they should be managed through the #settings method available
  # through the configured model. See ActiveRecord::Configuration.
  class Setting < ActiveRecord::Base

    # To avoid collisions with another Setting model that isn't from
    # ActiveConfiguration, this model and table is namespaced.
    set_table_name 'active_configuration_settings'

    # The model this Setting was created against.
    belongs_to :configurable, :polymorphic => true

    # Settings are looked up from their key.
    scope :with_key, lambda { |key|
      where(:key => key.to_s)
    }

    # Settings should be created through a configured model's
    # #active_configuration_settings relationship.
    attr_protected :configurable_type
    attr_protected :configurable_id

    # Settings must be related to some other model, have a key
    # and have a value. They do not necessarily need a modifier.
    validates_presence_of :configurable_type
    validates_presence_of :configurable_id
    validates_presence_of :key
    validates_presence_of :value
  end
end