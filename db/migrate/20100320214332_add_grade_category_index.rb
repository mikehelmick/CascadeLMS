class AddGradeCategoryIndex < ActiveRecord::Migration
  def self.up
    add_index(:grade_categories, [:course_id], :unique => false, :name => 'grade_category_course_idx')
  end

  def self.down
    remove_index :grade_categories, :name => :grade_category_course_idx
  end
end
