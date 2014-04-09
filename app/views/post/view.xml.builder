xml.instruct!
xml.post do
  xml.id "#{@item.id}"
  xml.user_id "#{@item.user_id}"
  xml.date "#{@item.created_at.to_formatted_s(:social_date)}"
  xml.user_name "#{@item.user.display_name rescue '?'}"
  unless @item.user.nil?
    xml.gravatar_url "#{@item.user.gravatar_url}"
  end
  unless @item.course.nil?
    xml.course_id "#{@item.course.id}"
    xml.course "#{@item.course.title}"
    xml.term "#{@item.course.term.semester}"
  end

  xml.aplus_count "#{@item.aplus_count}"
  xml.aplus_users do
    xml.user do
      @item.aplus_users(@user).each do |user|
        xml.id "#{user.id}"
        xml.name "#{user.display_name}"
        xml.gravatar_url "#{user.gravatar_url}"
      end
    end
  end
  xml.comment_count "#{@item.comment_count}"
  xml.comments do
    @item.item_comments.each do |comment|
      xml.comment do
        xml.user_id "#{comment.user.id}"
        xml.user "#{comment.user.display_name}"
        xml.gravatar_url "#{comment.user.gravatar_url}"
        xml.body_html do
          xml.cdata! comment.body_html
        end
        xml.created_at "#{comment.created_at}"
      end
    end
  end

xml.body do
  xml.cdata! @item.body
end
xml.body_html do
  xml.cdata! @item.body_html
end

if !@item.assignment_id.nil? && @item.assignment_id > 0
  if @item.assignment.quiz.nil?
    xml.assignment_quiz "false"
  else
    xml.assignment_quiz "true"
  end
  xml.assignment_id "#{@item.assignment.id}"
  xml.assignment_title "#{@item.assignment.title}"
end

if @item.wiki? && !@item.wiki.nil?
  xml.wiki "#{@item.wiki.page}"
end

if @item.forum? && !@item.forum_post.nil?
  xml.fourm_name "#{@item.fourm_post.fourm_topic.topic}"
  xml.fourm_post "#{@item.fourm_post.headline}"
  xml.fourm_post_id "#{@item.fourm_post.id}"
end

if @item.document? && !@item.document.nil?
  xml.document_id "#{@item.document.id}"
  xml.document_title "#{@item.document.title}"
  if item.document.link
    xml.document_url "#{@item.document.url}"
  end
  xml.document_comment do
    xml.cdata! item.document.comments_html
  end
end

if @item.blog_post? && !@item.post.nil?
  xml.blog_post_id "#{@item.post.id}"
  xml.blog_post_title "#{@item.post.title}"
end

end
