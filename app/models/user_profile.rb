class UserProfile < ActiveRecord::Base
  set_primary_key 'user_id'
  belongs_to :user
end
