class FeedSubscription < ActiveRecord::Base
  belongs_to :feed
  belongs_to :user
end
