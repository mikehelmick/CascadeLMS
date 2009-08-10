class CreateRubricLevels < ActiveRecord::Migration
  def self.up
    create_table :rubric_levels do |t|
      t.column :l1_name, :string, :null => false
      t.column :l2_name, :string, :null => false
      t.column :l3_name, :string, :null => false
      t.column :l4_name, :string, :null => false
      t.column :course_id, :int, :null => false

      t.timestamps
    end
    
    add_index(:rubric_levels, [:course_id], :unique => true)
    
    RubricLevel.create :l1_name => 'Excellent', :l2_name => 'Proficient', :l3_name => 'Apprentice', :l4_name => 'Novice', :course_id => 0
  end

  def self.down
    drop_table :rubric_levels
  end
end
