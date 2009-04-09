require 'MyTime'
class FreshItems
  
  def FreshItems.fresh( course, limit, include_comments = true, user_id = 0 )
    # show the last X items (whatever they may be)
    blog_entries = Post.find(:all, :conditions => ["course_id=? and published=?",course.id,true], :order => "created_at DESC", :limit => limit  )
    documents = Document.find(:all, :conditions => ["course_id=? and published=? and folder=?",course.id, true,false], :order => "created_at DESC", :limit => limit  )
    time = Time.new
    assignmentsUnfiltered = Assignment.find(:all, :conditions => ["course_id=? and open_date<=? and close_date>=?",course.id,time,time], :order => "open_date DESC", :limit => limit  )
    assignments = Array.new
    if user_id == 0
      assignments = assignmentsUnfiltered
    else
      assignmentsUnfiltered.each do |asgn|
        assignments << asgn if asgn.enabled_for_students_team?( user_id )
      end
    end
    
    recent_activity = Array.new
    blog_entries.each { |x| recent_activity << x }
    documents.each do |x| 
      ## X is not hidden
      published = true
      parent = x.parent_document
      
      while parent != nil
        published = published && parent.published
        parent = parent.parent_document
      end
      
      recent_activity << x if published
    end
    assignments.each { |x| recent_activity << x }
    
    if include_comments
      comments = Comment.find(:all, :conditions => ["course_id=?",course.id], :order => "created_at DESC", :limit => limit  )
      comments.each { |x| recent_activity << x }
    end
    
    # sort
    recent_activity.sort! do |a,b|
      if a.class.to_s.eql?("Assignment") && b.class.to_s.eql?("Assignment")
        a.open_date <=> b.open_date
      elsif a.class.to_s.eql?("Assignment")
        a.open_date <=> b.created_at
      elsif b.class.to_s.eql?("Assignment")
        a.created_at <=> b.open_date
      else
        a.created_at <=> b.created_at
      end
    end
    
    return recent_activity.reverse[0...limit]
  end
  
  def FreshItems.month( course, month ) 
    next_month = month.nextMonth
    
    blog_entries = Post.find(:all, :conditions => ["course_id=? and published=? and created_at >= ? and created_at <= ?",course.id,true,month,next_month], :order => "created_at asc" )
    documents = Document.find(:all, :conditions => ["course_id=? and published=? and folder=? and created_at >= ? and created_at <= ?",course.id, true,false,month,next_month], :order => "created_at asc" )
    assignments = Assignment.find(:all, :conditions => ["course_id=? and ((open_date>=? and open_date<=?) or (close_date>=? and close_date<=?))",course.id,month,next_month,month,next_month], :order => "open_date asc"  )
    
    recent_activity = Array.new
    blog_entries.each { |x| recent_activity << x }
    documents.each { |x| recent_activity << x }
    assignments.each { |x| recent_activity << x }
    
    # sort
    recent_activity.sort! do |a,b|
      if a.class.to_s.eql?("Assignment") && b.class.to_s.eql?("Assignment")
        a.open_date <=> b.open_date
      elsif a.class.to_s.eql?("Assignment")
        a.open_date <=> b.created_at
      elsif b.class.to_s.eql?("Assignment")
        a.created_at <=> b.open_date
      else
        a.created_at <=> b.created_at
      end
    end
    
    return recent_activity
  end
  
end