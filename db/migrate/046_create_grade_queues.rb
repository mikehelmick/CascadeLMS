class CreateGradeQueues < ActiveRecord::Migration
  def self.up
    create_table :grade_queues do |t|
      # t.column :name, :string
      
      t.column :user_id, :int, :null => false
      t.column :assignment_id, :int, :null => false
      t.column :user_turnin_id, :int, :null => false
      t.column :created_at, :datetime, :null => false
      t.column :updated_at, :datetime, :null => false
      
      t.column :serviced, :boolean, :null => false, :default => false
      t.column :acknowledged, :boolean, :null => false, :default => false
      t.column :queued, :boolean, :null => false, :default => false
    end
  end

  def self.down
    drop_table :grade_queues
  end
end
