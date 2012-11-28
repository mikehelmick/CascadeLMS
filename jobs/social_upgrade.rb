# Upgrades from CascadeLMS 1.4 to 1.5
# 
require 'MyString'

class SocialUpgrade
  
  def initialize()
  end

  def upgrade_users()
    puts "Creating feeds for all users"
    users = User.find(:all)
    users.each do |user|
      user.create_feed
    end
  end
  
  def execute()
    setting = Setting.find(:first, :conditions => ["name = ?", 'social_upgrade'])
    unless setting.value.eql?("0")
      puts "Social upgrade has already been run."
      return
    end

    upgrade_users()
    
    Course.transaction do
    courses = Course.find(:all, :order => "term_id DESC, id DESC")
    puts "Upgrading #{courses.size} courses to social"

    courses.each do |course|
      puts "Upgrading course #{course.short_description} (#{course.id}), term_id #{course.term_id}"
      Course.transaction do
        # Get the feed
        course_feed = course.create_feed
        
        # Subscribe the course users to the course feed.
        puts "Subscribing users to course feed."
        course.non_dropped_users.each do |user|
          course_feed.subscribe_user(user)
          puts " Subscribed #{user.display_name}"
        end
        
        # Assignments + Assignments being graded
        course.assignments.each do |assignment|
          if assignment.visible
            existing = Item.find(:first, :conditions => ["course_id = ? and assignment_id = ?", course.id, assignment.id])
            if existing.nil?
              puts "Assignment #{assignment.id}"
              item = assignment.create_item
              item.save
              item.share_with_course(course, assignment.open_date)
            end
            if assignment.released
              existing = Item.find(:first, :conditions => ["course_id = ? and graded_assignment_id = ?", course.id, assignment.id])
              if existing.nil?
                puts "Assignment released #{assignment.id}"
                item = assignment.create_graded_item
                item.save
                # Don't actually have a good date for released.
                item.share_with_course(course, assignment.close_date)
              end
            end
          end
        end

        # Blog Posts (post)
        course.posts.each do |post|
          if post.published
            existing = Item.find(:first, :conditions => ["course_id = ? and post_id = ?", course.id, post.id])
            if existing.nil?
              puts "Post #{post.id}"
              item = post.create_item
              item.comment_count = post.number_of_comments()
              item.save
              item.share_with_course(course, post.created_at)
            end
          end
        end

        # Documents
        course.documents.each do |document|
          if document.published
            unless document.folder
              existing = Item.find(:first, :conditions => ["course_id = ? and document_id = ?", course.id, document.id])
              if existing.nil?
                puts "Document #{document.id}"
                item = document.create_item
                item.save
                item.share_with_course(course, document.created_at)
              end
            end
          end
        end

        # Forum posts  
        course.forum_topics.each do |topic|
          # Only the first post from each topic should be posted
          forum_posts = ForumPost.find(:all, :conditions => ["forum_topic_id = ? and parent_post = ?", topic.id, 0])
          forum_posts.each do |forum_post|
            existing = Item.find(:first, :conditions => ["course_id = ? and forum_post_id = ?", course.id, forum_post.id])
            if existing.nil?
              puts "Forum post #{forum_post.id}"
              item = forum_post.create_item
              item.save
              item.share_with_course(course, forum_post.created_at)
            end
          end
        end

        # Wiki pages
        wikis = Wiki.find(:all, :conditions => ["course_id = ?", course.id])
        wikis.each do |wiki|
          existing = Item.find(:first, :conditions => ["course_id = ? and id = ?", course.id, wiki.id])
          if existing.nil?
            puts "Wiki #{wiki.id}"
            item = wiki.create_item
            item.save
            item.share_with_course(course, wiki.created_at)
          end
        end
      end
      setting.value = '1'
      setting.save
      end #transaction 
    end
  
  end
  
end

  
upgrade = SocialUpgrade.new()
upgrade.execute
