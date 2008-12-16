class CreateRubrics < ActiveRecord::Migration
  def self.up
    create_table :rubrics do |t|
      t.column :assignment_id, :integer, :null => false
      t.column :course_id, :integer, :null => false
      
      t.column :primary_trait, :text, :null => false
      
      t.column :no_credit_criteria, :text, :null => false
      t.column :no_credit_points, :integer, :null => false
      
      t.column :part_credit_criteria, :text, :null => false
      t.column :part_credit_points, :integer, :null => false
      
      t.column :full_credit_criteria, :text, :null => false
      t.column :full_credit_points, :integer, :null => false
      
      t.column :visible_before_grade_release, :boolean, :null => false, :default => true
      t.column :visible_after_grade_release, :boolean, :null => false, :default => true
      
      t.column :position, :integer
      
      t.timestamps
    end
    
    add_index(:rubrics, [:assignment_id], :unique => false)
    add_index(:rubrics, [:course_id], :unique => false)
  end

  def self.down
    drop_table :rubrics
  end
end
