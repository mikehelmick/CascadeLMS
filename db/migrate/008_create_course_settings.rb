class CreateCourseSettings < ActiveRecord::Migration
  def self.up
    create_table :course_settings, :id => false do |t|
      t.column :course_id, :integer
      
      t.column :enable_blog, :boolean, :null => false, :default => true
      t.column :blog_comments, :boolean, :null => false, :default => true
      
      t.column :enable_gradebook, :boolean, :null => false, :default => true
      
      t.column :enable_documents, :boolean, :null => false, :default => true
      
      t.column :enable_prog_assignments, :boolean, :null => false, :default => true
      t.column :enable_svn, :boolean, :null => false, :default => false
      t.column :svn_server, :text, :null => true
      
      t.column :enable_rss, :boolean, :null => false, :default => true
      
      t.column :ta_course_information, :boolean, :null => false, :default => false
      t.column :ta_course_documents, :boolean, :null => false, :default => false
      t.column :ta_course_assignments, :boolean, :null => false, :default => false
      t.column :ta_course_gradebook, :boolean, :null => false, :default => false
      t.column :ta_course_users, :boolean, :null => false, :default => false
      t.column :ta_course_blog_post, :boolean, :null => false, :default => false
      t.column :ta_course_blog_edit, :boolean, :null => false, :default => false
      t.column :ta_course_settings, :boolean, :null => false, :default => false
      t.column :ta_view_student_files, :boolean, :null => false, :default => true
      t.column :ta_grade_individual, :boolean, :null => false, :default => true
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :course_settings
  end
end
