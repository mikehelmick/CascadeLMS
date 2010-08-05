class EnableUploadsByDefault < ActiveRecord::Migration
  def self.up
    change_column( :assignments, :enable_upload, :boolean, :null => false, :default => true )
  end

  def self.down
    change_column( :assignments, :enable_upload, :boolean, :null => false, :default => false )
  end
end
