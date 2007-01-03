class CreateAssignmentPmdSettings < ActiveRecord::Migration
  def self.up
    create_table :assignment_pmd_settings do |t|
      t.column :assignment_id, :int
      t.column :style_check_id, :int
      t.column :enabled, :boolean, :null => false, :default => true
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :assignment_pmd_settings
  end
end
