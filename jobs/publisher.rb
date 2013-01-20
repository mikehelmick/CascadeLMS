# Background job for finding unpublished items and populating streams.
require 'MyString'

class Publisher
  def initialize()
    # nothing.
  end

  def run()
    publish_assignments()
    publish_documents()
    publish_blogs()

    unpublish_items()
    cleanup_feeds()
  end

  def self.publish_post(post)
    Item.transaction do
      item = Item.find(:first, :conditions => ["post_id = ?", post.id], :lock => true)
      if item.nil? && post.visible?
        item = post.create_item()
        item.save
        item.share_with_course(post.course, post.created_at)
        puts "Published blog post: #{post.id} (#{post.title}) course: #{post.course.id} (#{post.course.title})"
      end
    end
  end

  private
  def unpublish_items()
    # Find items that are deleted, but still staged in user's streams.
    rm_feeditems = FeedsItems.find(:all,
        :joins => ["left outer join items on feeds_items.item_id = items.id"],
        :conditions => ["items.id is null"])
    puts "Unpublishing #{rm_feeditems.size} records from feed_items"
    
    rm_feeditems.each do |fi|
      puts " Removing feed_id = #{fi.feed_id}, item_id = #{fi.item_id}"
      fi.destroy()
    end

    # Reomve the item shares
    rm_itemshares = ItemShare.find(:all,
        :joins => ["left outer join items on item_shares.item_id = items.id"],
        :conditions => ["items.id is null"])
    puts "Unpublishing #{rm_itemshares.size} records from item_shares"
    
    rm_itemshares.each do |is|
      puts " Removing item_share, item_id = #{is.item_id}"
      is.destroy
    end
  end

  # Find feed_items where the item ACL is no longer value for the user.
  # This is rare, as it means that a user has been dropped from the course.
  # This will only run order every 24 hours.
  def cleanup_feeds()
    status = Status.get_status('feed_item_cleanup')
    last_update = Time.at(status.value.to_i).to_i
    now = Time.now.to_i
    if (last_update + (24*60*60) < now)
      # Save the new status time first, since this could be a long cleanup.
      status.value = now.to_s
      status.save

      puts "Running garbage collection on feeds_items table."
      delete_count = 0;
      FeedsItems.find_each(:batch_size => 2000) do |feed_item|
        unless feed_item.feed.course_id.nil?
          user = feed_item.feed.user rescue user = nil
          item = feed_item.item rescue item = nil
          if user.nil? || item.nil? || !item.acl_check?(user)
            feed_item.destroy
            delete_count = delete_count + 1
          end
        end
      end
      puts "Done. Delete #{delete_count} feeds_items."
    else
      puts "Skipping GC of feeds_items table."
    end
  end

  def publish_assignments()
    assignments = Assignment.find(:all,
        :joins => ["left outer join items on items.assignment_id = assignments.id"],
        :conditions => ['assignments.visible = true and items.id is null'])
    puts "#{assignments.size} assignments to publish to stream."
    return if assignments.empty?

    assignments.each do |assignment|
      if assignment.publish()
        puts "Published assignment: #{assignment.id} (#{assignment.title}) course: #{assignment.course.id} (#{assignment.course.title})"
      end
    end
  end

  def publish_documents()
    documents = Document.find(:all,
        :joins => ["left outer join items on items.document_id = documents.id"],
        :conditions => ["documents.published = true and documents.folder = false and items.id is null"])
    puts "#{documents.size} documents to publish to stream."
    return if documents.empty?
    
    documents.each do |document|
      if document.publish()
        puts "Published document: #{document.id} (#{document.title}) course: #{document.course.id} (#{document.course.title})"
      end
    end  
  end

  def publish_blogs()
    posts = Post.find(:all,
        :joins => ["left outer join items on items.post_id = posts.id"],
        :conditions => ["posts.published = true and items.id is null"])
    puts "#{posts.size} posts to publish to stream."
    return if posts.empty?

    posts.each do |post|
      Publisher.publish_post(post)
    end
  end
end

pub = Publisher.new
pub.run()
