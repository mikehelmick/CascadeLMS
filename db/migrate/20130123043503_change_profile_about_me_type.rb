class ChangeProfileAboutMeType < ActiveRecord::Migration
  def self.up
    change_column(:user_profiles, :about_me, :text)
  end

  def self.down
  end
end
