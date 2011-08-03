module ActiveConfiguration
  
  # Generates a migration for the settings table.
  # 
  # Example:
  # 
  #   rails g active_configuration:install
  class InstallGenerator < Rails::Generators::Base
    include Rails::Generators::Migration
    
    def self.source_root
      File.join(File.dirname(__FILE__), 'templates')
    end
    
    def self.next_migration_number(dirname)
      if ActiveRecord::Base.timestamped_migrations
        Time.now.utc.strftime("%Y%m%d%H%M%S")
      else
        "%.3d" % (current_migration_number(dirname) + 1)
      end
    end
    
    def create_migration_file
      migration_template('create_active_configuration_settings.rb', 'db/migrate/create_active_configuration_settings.rb')
    end
  end
end