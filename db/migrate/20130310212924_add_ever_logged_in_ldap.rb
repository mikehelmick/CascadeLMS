class AddEverLoggedInLdap < ActiveRecord::Migration
  def self.up
    add_column(:users, :ever_ldap_auth, :boolean, :null => false, :default => false)
  end

  def self.down
    remove_column(:users, :ever_ldap_auth)
  end
end
