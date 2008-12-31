xml.instruct!
xml.blog_posts do
  @posts.each do |post|
    xml.blog_post do
      xml.id "#{post.id}"
      xml.title "#{post.title}"
      xml.featured "#{post.featured}"
      xml.author "#{post.user.display_name}"
      xml.posted_at CGI.rfc1123_date(post.created_at)
      xml.comments "#{post.comments.size}"
    end
  end
end