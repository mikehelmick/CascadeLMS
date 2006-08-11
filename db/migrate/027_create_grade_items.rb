class CreateGradeItems < ActiveRecord::Migration
  def self.up
    create_table :grade_items do |t|
      t.column :name, :string
      t.column :date, :date
      t.column :points, :float
      t.column :display_type, :char, :size => 1
      t.column :visible, :boolean, :null => false, :default => true
      t.column :grade_category_id, :int
      t.column :assignment_id, :int, :null => true
      t.column :course_id, :int, :null => false
    end
  end

  def self.down
    drop_table :grade_items
  end
end
