class AddAutoGradeIndices < ActiveRecord::Migration
  def self.up
    
    add_index(:io_check_results, [:io_check_id, :user_turnin_id], :unique => true)
    
  end

  def self.down
  end
end
