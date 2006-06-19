class CreateJournals < ActiveRecord::Migration
  def self.up
    create_table :journals do |t|
      t.column :assignment_id, :integer, :null => false
      t.column :user_id, :integer, :null => false
      t.column :start_time, :datetime, :null => true
      t.column :end_time, :datetime, :null => true
      t.column :interruption_time, :integer, :null => true
      t.column :completed, :boolean, :null => true
      t.column :comments, :text, :null => true
      
      # automagic fields
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :journals
  end
end
