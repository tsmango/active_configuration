class Category < ActiveRecord::Base
  
  # Define a default configuration that isn't used when running specs.
  # 
  if Rails.env.development?
    configure do
      option :sort do
        default  'alphabetical'
        restrict 'alphabetical', 'manual'
      end
      
      option :limit do
        format 'fixnum'
      end
      
      option :price_filter do
        format    'float'
        modifiers 'eq', 'lt', 'gt', 'lte', 'gte'
        multiple  true
      end
    end
  end
end
