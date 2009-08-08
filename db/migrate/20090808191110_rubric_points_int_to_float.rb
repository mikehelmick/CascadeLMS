class RubricPointsIntToFloat < ActiveRecord::Migration
  def self.up
    change_column(:rubrics, :no_credit_points, :float, :null => false)
    change_column(:rubrics, :part_credit_points, :float, :null => false)
    change_column(:rubrics, :full_credit_points, :float, :null => false)
    change_column(:rubrics, :above_credit_points, :float, :null => false)
  end

  def self.down
  end
end
