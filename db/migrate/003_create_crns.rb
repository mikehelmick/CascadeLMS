class CreateCrns < ActiveRecord::Migration
  def self.up
    create_table :crns do |t|
      t.column :crn, :string, :limit => 20, :null => false
      t.column :name, :string, :null => false
      # t.column :name, :string
    end
    
    Crn.create :crn => 'NONE', :name => 'NONE'
  end

  def self.down
    drop_table :crns
  end
end
