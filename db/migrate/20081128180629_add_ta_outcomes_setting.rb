class AddTaOutcomesSetting < ActiveRecord::Migration

  def self.up
    add_column( :course_settings, :ta_edit_outcomes, :boolean, :null => false, :default => false )
  end

  def self.down
    remove_column( :course_settings, :ta_edit_outcomes )
  end

  
end
