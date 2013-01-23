class UserProfile < ActiveRecord::Base
  set_primary_key 'user_id'
  belongs_to :user

  def empty?
    major.nil? && year.nil? && about_me.nil?
  end
end
