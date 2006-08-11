class CreateGradeEntries < ActiveRecord::Migration
  def self.up
    create_table :grade_entries do |t|
      t.column :grade_item_id, :int
      t.column :user_id, :int
      t.column :course_id, :int
      t.column :points, :float
      # t.column :name, :string
    end
    
    add_index(:grade_entries, :grade_item_id)
    add_index(:grade_entries, :user_id)
  end

  def self.down
    drop_table :grade_entries
  end
end
