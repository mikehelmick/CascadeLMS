class CreateGradeItems < ActiveRecord::Migration
  def self.up
    create_table :grade_items do |t|
      t.column :name, :string
      t.column :date, :date
      t.column :points, :int
      t.column :display_flag, :char, :size => 1
      t.column :visible, :boolean, :null => false, :default => true
      t.column :grade_category_id, :int
    end
  end

  def self.down
    drop_table :grade_items
  end
end
