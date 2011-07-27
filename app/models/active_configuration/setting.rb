module ActiveConfiguration
  class Setting < ActiveRecord::Base
    belongs_to :configurable, :polymorphic => true
    
    scope :with_key, lambda { |key|
      where(:key => key.to_s)
    }
    
    attr_protected :configurable_type
    attr_protected :configurable_id
    
    validates_presence_of :configurable_type
    validates_presence_of :configurable_id
    validates_presence_of :key
    validates_presence_of :value
  end
end