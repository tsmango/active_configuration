class CreateActiveConfigurationSettings < ActiveRecord::Migration
  def self.up
    create_table ActiveConfiguration::Config.table_name do |t|
      t.string  :configurable_type
      t.integer :configurable_id
      t.string  :key
      t.string  :modifier
      t.text    :value
      t.timestamps
    end
  end

  def self.down
    drop_table ActiveConfiguration::Config.table_name
  end
end