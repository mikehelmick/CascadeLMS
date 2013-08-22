class UpdateRubricDefaults < ActiveRecord::Migration
  def self.up
    change_column(:rubrics, :no_credit_points, :float, {:null => false, :default => 0.0})
    
    change_column(:rubrics, :part_credit_points, :float, {:null => false, :default => 0.0})
    
    change_column(:rubrics, :full_credit_points, :float, {:null => false, :default => 0.0})
    
    change_column(:rubrics, :above_credit_points, :float, {:null => false, :default => 0.0})
  end

  def self.down
    # no reason to down migration - new columns are backwards compatible
  end
end
