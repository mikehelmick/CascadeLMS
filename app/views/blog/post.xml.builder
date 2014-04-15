xml.instruct!
xml.blog_post do
  xml.id "#{@post.id}"
  xml.title "#{@post.title}"
  xml.featured "#{@post.featured}"
  xml.author "#{@post.user.display_name}"
  xml.posted_at CGI.rfc1123_date(@post.created_at)
  xml.body do
    xml.cdata! "#{@post.body_html}"
  end
  
  unless @post.item.nil?
    xml.aplus_count "#{@post.item.aplus_count}"
    xml.aplus_users do
      xml.user do
        @post.item.aplus_users(@user).each do |user|
          xml.user do
            xml.id "#{user.id}"
            xml.name "#{user.display_name}"
            xml.gravatar_url "#{user.gravatar_url}"
          end
        end
      end
    end
  end
  
  xml.comments do
    @post.comments.each do |comment|
      xml.comment do
        xml.author "#{comment.user.display_name}"
        xml.posted_at CGI.rfc1123_date(comment.created_at)
        xml.body do
          xml.cdata! "#{comment.body_html}"
        end
      end
    end
  end
end