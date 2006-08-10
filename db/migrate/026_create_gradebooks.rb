class CreateGradebooks < ActiveRecord::Migration
  def self.up
    create_table :gradebooks, :id => false do |t|
      t.column :course_id, :integer
      t.column :weight_grades, :boolean, :null => false, :default => false
      t.column :show_total, :boolean, :null => false, :default => true
    end
    
    add_index(:gradebooks, :course_id, :unique => true)
  end

  def self.down
    drop_table :gradebooks
  end
end
