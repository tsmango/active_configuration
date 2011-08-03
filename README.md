# ActiveConfiguration

ActiveConfiguration is a Rails 3.x engine for reading and writing settings, in 
a flexible manner, against ActiveRecord models. This engine is meant to be used 
with a highly configurable application so that you don't necessarily need to 
setup specific columns and tables for handling similar style configurations.

The idea is to simply offer a generic, configurable, settings store that can 
be made available to any of your models that need it. If your application isn't 
very configurable, ActiveConfiguration is probably overkill.

## Source

The source for this engine is located at:

	http://github.com/tsmango/active_configuration

## Installation

Add the following to your Gemfile:

	gem 'active_configuration'

Generate the migration for the active\_configuration\_settings table:

	rails g active_configuration:install

Migrate your database:

	rake db:migrate

## Example Configuration

	class Category < ActiveRecord::Base
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

After installing ActiveConfiguration, the #configure block is exposed to every 
ActiveRecord model. If the #configure block is defined, with valid 
configuration details, additional methods are made available on instances.

## Example Usage

Given we have defined the `Category` class above. Instance will now have a #settings 
method where settings can be read from and written to.

	>> category = Category.create(:name => 'Vinyl Records')
	=> #<Category id: 1, name: "Vinyl Records", created_at: "2011-08-03 15:46:11", updated_at: "2011-08-03 15:46:11">
	
	?> category.settings
	=> #<ActiveConfiguration::SettingManager:0x10e7d1950 @configurable=#<Category id: 1, name: "Vinyl Records", created_at: "2011-08-03 15:46:11", updated_at: "2011-08-03 15:46:11">>
	
	?> category.settings.sort
	=> {:value=>"alphabetical", :modifier=>nil}
	
	?> category.settings.sort[:value]
	=> "alphabetical"
	
	?> category.settings.sort.update(:value => 'manual')
	=> true
	
	?> category.settings.price_filter
	=> []
	
	?> category.settings.price_filter.update({:modifier => 'gt', :value => 10.00}, {:modifier => 'lte', :value => 25.00})
	=> true
	
	?> category.settings.price_filter
	=> [{:value=>10.0, :modifier=>"gt"}, {:value=>25.0, :modifier=>"lte"}]

The above shows the basic interaction with the settings system. Your 
application would read and write configured settings from this 
underlying settings store and use the values however it would normally 
use specifically designed setting columns and tables.

For example, if you had a `Category` model that only had a configurable 
`sort` attribute, ActiveConfiguration would be overkill. Rather, you 
would just read and write values using a specific `sort` column.

However, if your `Category` model was more flexible in its configuration, 
you may want a `sort` setting, a `limit` setting and multiple `price_filter` 
setting that can be configured by your end users. Without ActiveConfiguration, 
you would have to develop a way to store these price filtering rules. With 
ActiveConfiguration, these price filter rules can be stored in a generic way.

## Tests

The spec/ directory contains a skeleton Rails 3.0.0 application for testing 
purposes. All specs can be found in spec/spec/.

To run the specs, do the following from the root of active\_configuration:

	bundle install --path=vendor/bundles --binstubs
	bin/rspec spec

## License

Copyright &copy; 2011 Thomas Mango, released under the MIT license