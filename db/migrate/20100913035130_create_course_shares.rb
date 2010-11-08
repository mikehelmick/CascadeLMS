class CreateCourseShares < ActiveRecord::Migration
  def self.up
    create_table :course_shares do |t|
      t.column :user_id, :integer, :null => false
      t.column :course_id, :integer, :null => false
      
      t.column :assignments, :boolean, :null => false, :default => false
      t.column :documents, :boolean, :null => false, :default => false
      t.column :blogs, :boolean, :null => false, :default => false
      t.column :outcomes, :boolean, :null => false, :default => false
      t.column :rubrics, :boolean, :null => false, :default => false

      t.timestamps
    end
    add_index(:course_shares, [:user_id, :course_id], :unique => true)
  end

  def self.down
    drop_table :course_shares
  end
end

