class Notification < ActiveRecord::Base
  
  belongs_to :user
  
  def Notification.create( text, users, link = nil )
    users.each do |user|
      notification = Notification.new
      notification.notification = text
      notification.user = user
      notification.link = link
      notification.emailed = false
      notification.acknowledged = false
      notification.save
    end
    
  end
  
end
