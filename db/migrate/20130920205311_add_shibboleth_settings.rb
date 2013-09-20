class AddShibbolethSettings < ActiveRecord::Migration
  def self.up
    # Some possible setting, defaults based on the University of Cincinnati's shibboleth configuration.
    Setting.create :name => 'shib_field_mail', :value => 'mail', :description => 'Shibboleth email variable'
    Setting.create :name => 'shib_field_title', :value => 'title', :description => 'Shibboleth personal title variable'
    Setting.create :name => 'shib_field_affiliation', :value => 'uceduAffiliation', :description => 'Shibboleth organization affiliation variable'
    Setting.create :name => 'shib_instructor_affiliation', :value => 'Faculty', :description => 'Shibboleth affiliation value that indicates instructor'
    Setting.create :name => 'shib_field_uid', :value => 'cn', :description => 'Shibboleth unique ID variable'
    Setting.create :name => 'shib_field_firstname', :value => 'givenName', :description => 'Shibboleth first name variable'
    Setting.create :name => 'shib_field_lastname', :value => 'sn', :description => 'Shibboleth last name variable'
    Setting.create :name => 'shib_field_phone', :value => 'telephoneNumber', :description => 'Shibboleth phone variable'
    Setting.create :name => 'shib_field_org_id', :value => 'uceduUCID', :description => 'Shibboleth organization id variable, optional.'
    Setting.create :name => 'shib_field_persistent_id', :value => 'persistent-id', :description => 'Shibboleth persistent ID, used to obsfuscate the password field, not retained'

    add_column(:users, :shibboleth_auth, :boolean, :null => false, :default => false)
    add_column(:users, :title, :string, :null => true)
    add_column(:users, :org_id, :string, :null => true)
  end

  def self.down
    remove_column(:users, :shibboleth_auth)
    remove_column(:users, :title)
    remove_column(:users, :org_id)
    
    execute <<-SQL
      delete from settings where name like 'shib_%';
    SQL
  end
end
