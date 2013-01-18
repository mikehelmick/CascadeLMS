class CreateStatuses < ActiveRecord::Migration
  def self.up
    create_table :statuses do |t|
      t.column :name, :string, :null => false
      t.column :value, :text, :null => false
      t.timestamps
    end
    add_index(:statuses, [:name], :unique => true)

    Status.create :name => 'tickle', :value => '0'
  end

  def self.down
    drop_table :statuses
  end
end
