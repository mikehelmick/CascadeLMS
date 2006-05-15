class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :users do |t|
      t.column :uniqueid, :string, :limit => 15, :null => false
      t.column :prefered_name, :string
      t.column :first_name, :string
      t.column :middle_name, :string
      t.column :last_name, :string
      t.column :instructor, :string, :limit => 1, :null => false, :defalt => 'N'
      t.column :affiliation, :string
      t.column :personal_title, :string
      t.column :office_hours, :string
      t.column :phone_number, :string
    end
  end

  def self.down
    drop_table :users
  end
end
