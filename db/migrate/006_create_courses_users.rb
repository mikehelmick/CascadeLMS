class CreateCoursesUsers < ActiveRecord::Migration
  def self.up
    create_table( :courses_users, :id => false, :primary_key => 'course_id, user_id' ) do |t|
      t.column :user_id, :integer, :null => false
      t.column :course_id, :integer, :null => false
      t.column :course_student, :boolean, :null => false, :default => true
      t.column :course_instructor, :boolean, :null => false, :default => false
      t.column :course_guest, :boolean, :null => false, :default => false
      t.column :course_assistant, :boolean, :null => false, :default => false
      # t.column :name, :string
    end
    add_index(:courses_users, [:user_id, :course_id], :unique => true)
  end

  def self.down
    drop_table :courses_users
  end
end
