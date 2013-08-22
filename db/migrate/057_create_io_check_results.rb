class CreateIoCheckResults < ActiveRecord::Migration
  def self.up
    create_table :io_check_results do |t|
      
      t.column :io_check_id, :integer, :null => false
      t.column :user_id, :integer, :null => false
      t.column :user_turnin_id, :integer, :null => false
      
      t.column :output, :text, :null => false
      t.column :diff_report, :text, :null => false
      t.column :match_percent, :float, :null => false
      
      t.column :created_at, :datetime, :null => false
      
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :io_check_results
  end
end
