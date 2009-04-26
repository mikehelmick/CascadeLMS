class AddProgramApiFlag < ActiveRecord::Migration
  def self.up
    add_column( :programs, :enable_api, :boolean, :null => false, :default => false )
  end

  def self.down
    remove_column( :programs, :enable_api )
  end
end
