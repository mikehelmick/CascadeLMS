class CreateGradeCategories < ActiveRecord::Migration
  def self.up
    create_table :grade_categories do |t|
      t.column :category, :string
      t.column :course_id, :integer, :null => false, :default => 0
      # t.column :name, :string
    end
    
    GradeCategory.create :category => 'Homework', :course_id => 0
    GradeCategory.create :category => 'Quiz', :course_id => 0
    GradeCategory.create :category => 'Exam', :course_id => 0
    GradeCategory.create :category => 'Final Exam', :course_id => 0
    GradeCategory.create :category => 'Assignment', :course_id => 0
    GradeCategory.create :category => 'Program', :course_id => 0
    GradeCategory.create :category => 'Programming Quiz', :course_id => 0
    GradeCategory.create :category => 'Group Project', :course_id => 0
  end

  def self.down
    drop_table :grade_categories
  end
end
