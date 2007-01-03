class CrnAddTitle < ActiveRecord::Migration
  def self.up
     add_column( :crns, :title, :string, :null => true )
  end

  def self.down
    remove_column( :crns, :title )
  end
end
