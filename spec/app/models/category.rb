class Category < ActiveRecord::Base
  configure do
    option :sort do
      default  :alphabetical
      restrict :alphabetical, :manual
    end
    
    option :containment_rule_price do
      format    :float
      modifiers :eq, :lt, :gt, :lte, :gte
      multiple  true
    end
  end
end
