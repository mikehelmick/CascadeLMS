Jbuilder.encode do |json|
  json.announcements @announcements do |announcement|
    json.announcement do
      json.id announcement.id
      json.headline "#{announcement.headline}"
      json.text "#{announcement.text}"
      json.start CGI.rfc1123_date(announcement.start)
      json.end CGI.rfc1123_date(i=announcement.end)
    end
  end


  json.notifications @notifications do |notification|
    json.notification = notification.notification
  end

  json.current_courses @courses do |course|
    json.id course.course.id
    json.title "#{course.course.title}"
    json.short_description "#{course.course.short_description}"
  end

  json.past_courses @other_courses do |course|
    json.id course.id
    json.title "#{course.title}"
    json.short_description "#{course.short_description}"
  end
end # overall end