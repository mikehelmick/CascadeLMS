# Background Job for handling an APlus action and turning it into a notification.
require 'MyString'

class AplusNotify
  def initialize(item_id, user_id, link)
    @item_id = item_id
    @user_id = user_id
    @link = link
  end

  def run()
    puts "APlus item:#{@item_id} user:#{@user_id}"
    item = Item.find(@item_id)
    aplus_user = User.find(@user_id)

    # if the item has no user attached (some in the upgrade path are like this), then exit.
    if item.user.nil?
      puts "Item has no user to notify."
      return
    end

    if item.user.id == aplus_user.id
      puts "Actor is owner, no notification"
      return
    end

    puts "Creating notification for #{item.user.display_name}"
    item.notify_for_aplus(aplus_user, @link)    
  end
end

# params
# item_id
# user_id (user that did the APlus action)
item_id = ARGV[0].to_i
user_id = ARGV[1].to_i
link = ARGV[2]

notify = AplusNotify.new(item_id, user_id, link)
notify.run()

