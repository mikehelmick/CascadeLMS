class CreateExtensions < ActiveRecord::Migration
  def self.up
    create_table :extensions do |t|
      t.column :assignment_id, :integer
      t.column :user_id, :integer
      
      t.column :extension_date, :datetime
      
      t.timestamps
    end
    
    add_index(:extensions, [:assignment_id], :name => :extension_assignment_id_idx, :unique => false)
    add_index(:extensions, [:assignment_id, :user_id], :name => :extension_assignment_user_idx, :unique => true)
  end

  def self.down
    drop_table :extensions
  end
end
