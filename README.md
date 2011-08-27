# ActiveConfiguration

ActiveConfiguration is an engine that exposes a generic settings store to 
ActiveRecord models. Made for very configurable applications, it allows you 
to avoid implementing specific ways to store settings for each model that 
needs such a configuration. If your application isn't very configurable, 
ActiveConfiguration isn't what you want.

If you had a `Category` model that only had a configurable `sort` attribute, 
ActiveConfiguration would be overkill. Rather, you would just read and write 
values using a specific `sort` column and restrict the allowed values using 
something like `validates_inclusion_of`.

However, if your `Category` model was more flexible in its configuration, you 
may want a `sort` setting, a `limit` setting and multiple `price_filter` 
settings that can be configured by your end user. Without ActiveConfiguration, 
you would have to develop a way to store and validate these settings for this 
specific scenario. The `sort` and `limit` settings are simple but because 
`price_filter` can accept multiple rules, you'd have to set up an additional 
model. Still, this isn't really an issue when you're dealing with just a single 
configurable model. When you're dealing with many, things tend to get messy.

With ActiveConfiguration, all of your settings, even for `price_filter`, can 
be stored in a generic way. ActiveConfiguration provides a place to store 
settings for each of your models and even handles validation when you restrict 
the allowed values or format of an option.

## Source

The source for this engine is located at:

	http://github.com/tsmango/active_configuration

## Installation

Add the following to your Gemfile:

	gem 'active_configuration'

Generate the migration for the `settings` table:

	rails g active_configuration:install

Note: The table can be changed from `settings` to something else by specifying 
a config option in an initializer like:

	# config/initializers/active_configuration.rb
	
	Rails.configuration.active_configuration_table_name = 'active_configuration_settings'

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

After installing ActiveConfiguration, the #configure block is available to 
every ActiveRecord model. If the #configure block is defined with a valid 
configuration, additional methods are made available on the model.

## Example Usage

Given we have defined the `Category` class above, instances will now have a #settings 
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

Note:

* Using the #update method will add any errors to your model's errors hash.
* Using the #update! method will raise `ActiveConfiguration::Error`s instead.

For more details, see `lib/active_configuration/setting_proxy.rb`.

## Testing Environment

The spec/ directory contains a skeleton Rails 3.0.0 application for testing 
purposes. All specs can be found in spec/spec/.

To run the specs, do the following from the root of active\_configuration:

	bundle install --path=vendor/bundles --binstubs
	bin/rspec spec

## License

Copyright &copy; 2011 Thomas Mango, released under the MIT license.