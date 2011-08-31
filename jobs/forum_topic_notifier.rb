require "redcloth_formatters_plain"

class ForumTopicNotifier 
  
  def initialize( topic_id, post_id, link, replyLink, unwatchLink)
    @topicId = topic_id
    @postId = post_id
    @link = link
    @replyLink = replyLink
    @unwatchLink = unwatchLink
  end
  
  def execute    
    puts "Doing forum notifications for topic: #{@topidId}, #{@postId}"
    @topic = ForumTopic.find(@topicId)
    @post = ForumPost.find(@postId)
    
    if ( @post.forum_topic_id == @topic.id ) 
      # find all the watches
      emailUsers = Array.new
      
      watches = ForumWatch.find(:all, :conditions => ["forum_topic_id = ?", @topic.id])
      watches.each do |watch|
        user = watch.user
        unless user.nil?
          subject = "#{@topic.course.title}: New forum post in topic '#{@topic.topic}'"
          part = if @post.parent_post == 0
                   "started a new thread: '#{@post.headline}'.\n"
                 else
                   "posted a reply: '#{@post.headline}'.\n"
                 end
          post_plaintext = RedCloth.new(@post.body).to_plain
          
          emailBody = "Hello #{user.display_name}\nYou are currently watching the forum '#{@topic.topic}' in the class #{@topic.course.title}.\n\n" +
                      "#{@post.user.display_name} has #{part} at #{@post.created_at.to_formatted_s(:long)}\n" +
                      "\n" +
                      "To view the full thread, please click here: #{@link}\n" +
                      "To reply click here: #{@replyLink}\n" +
                      "--------------------------------------------------------------" +
                      "Post by :#{@post.user.display_name} at #{post.created_at.to_formatted_s(:long)}\n" +
                      "\n" +
                      "#{post_plaintext}" +
                      "\n--------------------------------------------------------------" +
                      "To view the full thread, please click here: #{@link}\n" +
                      "To reply click here: #{@replyLink}\n" +
                      "\n" +
                      "If you no longer wish to watch this topic, click here: #{@unwatchLink}.\n\n"
                      
 
          # send each user an email
          Notifier::deliver_send_forum_email( user, emailBody, subject, user )
            
          puts "Sent email to #{user.display_name} - #{user.email}"
        end
      end
      
    end     
  end
  
end

if ARGV.size == 3
  # In case there are any jobs in the queue when the upgrade happens
  job = ForumTopicNotifier.new( ARGV[0].to_i, ARGV[1].to_i, ARGV[2],  "Visit CascadeLMS",  "Visit CascadeLMS" )
  job.execute
  exit(0)
elsif ARGV.size == 5
  job = ForumTopicNotifier.new( ARGV[0].to_i, ARGV[1].to_i, ARGV[2],  ARGV[3],  ARGV[4] )
  job.execute
  exit(0)
else
  puts "Incorrect number of arguments!"
  exit(1)
end