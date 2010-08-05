class AddTwitterSettings < ActiveRecord::Migration
  def self.up
    Setting.create :name => 'enableTwitter', :value => 'false', :description => 'Enable twitter "true" or "false".'
    Setting.create :name => 'oauth_consumer_key', :value => 'Your OAuth Consumer Key for Twitter', :description => 'Your OAuth Consumer Key for Twitter.'
    Setting.create :name => 'oauth_consumer_secret', :value => 'Your OAuth Consumer Secret for Twitter', :description => 'Your OAuth Consumer Secret for Twitter.'
  end

  def self.down
  end
end
