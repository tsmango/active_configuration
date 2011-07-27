class CreateSettings < ActiveRecord::Migration
  def change
    create_table :settings do |t|
      t.string  :configurable_type
      t.integer :configurable_id
      t.string  :key
      t.string  :value
      t.string  :modifier
      t.timestamps
    end
  end
end