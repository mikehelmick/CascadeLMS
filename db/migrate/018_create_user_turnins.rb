class CreateUserTurnins < ActiveRecord::Migration
  def self.up
    create_table :user_turnins do |t|
      t.column :assignment_id, :integer
      t.column :user_id, :integer
      
      t.column :position, :integer
      t.column :sealed, :boolean, :null => false, :default => false
      
      t.column :created_at, :datetime, :null => false
      t.column :updated_at, :datetime, :null => false
      
    end
  end

  def self.down
    drop_table :user_turnins
  end
end
