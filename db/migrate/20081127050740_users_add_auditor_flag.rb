class UsersAddAuditorFlag < ActiveRecord::Migration
  def self.up
      add_column( :users, :auditor, :boolean, :null => false, :default => false )

      # add setting for alow fallback auth
      Setting.create :name => 'allow_fallback_auth', :value => 'true', :description => 'If LDAP authentication fails  -  should local, basic authentication be used.   It is recommended that this setting only be used when a non-LDAP account is required.'
  end

  def self.down
      remove_column( :users, :auditor )
  end
end
