# Background Job for handling an APlus action and turning it into a notification.
require 'MyString'

class CommentNotify
  def initialize(item_id, user_id, link)
    @item_id = item_id
    @user_id = user_id
    @link = link
  end

  def run()
    puts "Comment item:#{@item_id} user:#{@user_id}"
    item = Item.find(@item_id)
    comment_user = User.find(@user_id)

    # No restrictions on notification creation, since we want to notify previous commenters.
    notified = item.notify_for_comment(comment_user, @link) 
    if notified.empty?
      puts "No notifications created."
    else  
      puts "Created notifications for #{notified.entries.join(', ')}"
    end
  end
end

# params
# item_id
# user_id (user that did the APlus action)
item_id = ARGV[0].to_i
user_id = ARGV[1].to_i
link = ARGV[2]

notify = CommentNotify.new(item_id, user_id, link)
notify.run()

