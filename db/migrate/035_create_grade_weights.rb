class CreateGradeWeights < ActiveRecord::Migration
  def self.up
    create_table :grade_weights do |t|
      t.column :grade_category_id, :integer, :null => false
      t.column :percentage, :float, :null => false, :default => 0
      t.column :gradebook_id, :integer, :null => false
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :grade_weights
  end
end
