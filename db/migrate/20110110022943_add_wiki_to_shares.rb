class AddWikiToShares < ActiveRecord::Migration
  def self.up
    add_column( :course_shares, :wiki, :boolean, :null => false, :default => false )
  end

  def self.down
    remove_column( :course_shares, :wiki )
  end
end
