class CreateTempFiles < ActiveRecord::Migration
  def self.up
    create_table :temp_files do |t|
      t.column :filename, :text
      t.column :save_until, :datetime
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :temp_files
  end
end
