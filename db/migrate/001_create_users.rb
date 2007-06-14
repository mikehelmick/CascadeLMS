class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :users do |t|
      t.column :uniqueid, :string, :limit => 15, :null => false
      t.column :password, :string, :null => true
      t.column :preferred_name, :string
      t.column :first_name, :string, :null => false
      t.column :middle_name, :string
      t.column :last_name, :string, :null => false
      t.column :instructor, :boolean, :null => false, :defalt => false
      t.column :admin, :boolean, :null => false, :default => false
      t.column :affiliation, :string
      t.column :personal_title, :string
      t.column :office_hours, :string
      t.column :phone_number, :string
      t.column :email, :string, :null => false
    end
    
    ### create the admin user
    user = User.new
    user.uniqueid = 'admin'
    user.password = 'password'
    user.first_name = 'Admin'
    user.last_name = 'Admin'
    user.instructor = true
    user.admin = true
    user.affiliation = 'Faculty'
    user.email = 'changeme@soon.edu'
    user.save
  end

  def self.down
    drop_table :users
  end
end
