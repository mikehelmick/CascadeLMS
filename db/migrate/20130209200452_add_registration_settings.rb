class AddRegistrationSettings < ActiveRecord::Migration
  def self.up
    Setting.create :name => 'auth_self_registration', :value => 'true', :description => 'Allow users to self register.'
    Setting.create :name => 'auth_self_registration_domain', :value => '',
        :description => 'If set, a comma seperated list of domains to limit registration to. Email addresses used to register must be in one of these domains.'
  end

  def self.down
    Setting.delete_all('name = "auth_self_registration"')
    Setting.delete_all('name = "auth_self_registration_domain"')
  end
end
