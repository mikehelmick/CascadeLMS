class CreateAssignments < ActiveRecord::Migration
  def self.up
    create_table :assignments do |t|
      t.column :course_id, :integer
      t.column :position, :integer
      
      t.column :title, :string
      t.column :open_date, :datetime
      t.column :due_date, :datetime
      t.column :close_date, :datetime
      t.column :description, :text, :null => true
      t.column :description_html, :text, :null => true
      t.column :file_uploads, :boolean, :null => false, :default => false
      
      t.column :enable_upload, :boolean, :null => false, :default => false
      t.column :enable_journal, :boolean, :null => false, :default => true
      t.column :programming, :boolean, :null => false, :default => true
      t.column :use_subversion, :boolean, :null => false, :default => true
      t.column :subversion_server, :string, :null => true
      t.column :subversion_development_path, :string, :null => true
      t.column :subversion_release_path, :string, :null => true
      t.column :auto_grade, :boolean, :null => false, :default => false
      
      t.column :grade_category_id, :integer 
    end
  end

  def self.down
    drop_table :assignments
  end
end
