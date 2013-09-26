class AddGradebookExtensionTracking < ActiveRecord::Migration
  def self.up
    add_column(:gradebooks, :track_extensions, :boolean, :null => false, :default => false)
    add_column(:gradebooks, :extension_hours, :integer, :null => false, :default => 0)
  end

  def self.down
    remove_column(:gradebooks, :track_extensions)
    remove_column(:gradebooks, :extension_hours)
  end
end
