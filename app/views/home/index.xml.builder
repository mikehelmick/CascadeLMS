xml.instruct!
xml.home do
  xml.announcements do
    @announcements.each do |i|
      xml.announcement do
        xml.id "#{i.id}"
        xml.headline "#{i.headline}"
        xml.text "#{i.text}"
        xml.start CGI.rfc1123_date(i.start)
        xml.end CGI.rfc1123_date(i.end)
      end
    end
  end

  xml.notifications do
    @notifications.each do |i|
      xml.notification = i.notification
    end
  end

  xml.feed_items do
    @feed_items.each do |i|
      xml.id "#{i.item.id}"
      xml.user_id "#{i.item.user_id}"
      xml.date "#{i.item.created_at}"
      xml.user_name "#{i.item.user.display_name rescue '?'}"
      unless i.item.user.nil?
        xml.gravatar_url "#{i.item.user.gravatar_url}"
      end
      unless i.item.course.nil?
        xml.course_id "#{i.item.course.id}"
        xml.course "#{i.item.course.title}"
        xml.term "#{i.item.course.term.semester}"
      end

      xml.aplus_count "#{i.item.aplus_count}"
      xml.aplus_users do
        xml.user do
          i.item.aplus_users(@user).each do |user|
            xml.id "#{user.id}"
            xml.name "#{user.display_name}"
            xml.gravatar_url "#{user.gravatar_url}"
          end
        end
      end
      xml.comment_count "#{i.item.comment_count}"

      xml.body do
        xml.cdata! i.item.body
      end
      xml.body_html do
        xml.cdata! i.item.body_html
      end

      if !i.item.assignment_id.nil? && i.item.assignment_id > 0
        if i.item.assignment.quiz.nil?
          xml.assignment_quiz "false"
        else
          xml.assignment_quiz "true"
        end
        xml.assignment_id "#{i.item.assignment.id}"
        xml.assignment_title "#{i.item.assignment.title}"
      end

      if i.item.wiki? && !i.item.wiki.nil?
        xml.wiki "#{i.item.wiki.page}"
      end

      if i.item.forum? && !i.item.forum_post.nil?
        xml.fourm_name "#{i.item.fourm_post.fourm_topic.topic}"
        xml.fourm_post "#{i.item.fourm_post.headline}"
        xml.fourm_post_id "#{i.item.fourm_post.id}"
      end

      if i.item.document? && !i.item.document.nil?
        xml.document_id "#{i.item.document.id}"
        xml.document_title "#{i.item.document.title}"
        if i.item.document.link
          xml.document_url "#{i.item.document.url}"
        end
        xml.document_comment do
          xml.cdata! i.item.document.comments_html
        end
      end

      if i.item.blog_post? && !i.item.post.nil?
        xml.blog_post_id "#{i.item.post.id}"
        xml.blog_post_title "#{i.item.post.title}"
      end


    end
  end

  xml.pages do
    1.upto(@pages.page_count) do |i|
      xml.page i
    end
  end

  #xml.current_courses do
  #  @courses.each do |cuser|
  #    xml.course do
  #      xml.id "#{cuser.course.id}"
  #      xml.title "#{cuser.course.title}"
  #      xml.short_description "#{cuser.course.short_description}"
  #    end
  #  end
  #end

  #xml.past_courses do
  #  @other_courses.each do |course|
  #    xml.past_course do
  #      xml.id "#{course.id}"
  #      xml.title "#{course.title}"
  #      xml.short_description "#{course.short_description}"
  #    end
  #  end
  #end
end # overall end
