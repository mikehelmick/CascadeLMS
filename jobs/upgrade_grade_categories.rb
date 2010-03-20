# A job that upgrades grade cateogires

class UpgradeGradeCategories
  
  def initialize( course_id, type, mappings )
    @course_id = course_id
    @type = type
    
    @mappings = Hash.new
    i = 0
    while i < mappings.size
      @mappings[mappings[i].to_i] = mappings[i+1].to_i
      i = i + 2 
    end
  end
  
  def execute()
    # load the course
    course = Course.find(@course_id)
    
    # instructors will be needed for notifications
    instructors = course.instructors
    
    @mappings.keys.each do |key|
      # update assignments for this mapping
      Assignment.update_all("grade_gategory_id = #{@mappings[key]}", ["course_id = ? and grade_category_id = ?", @course_id, key])
      
      # update grade_items for this mapping
      GradeItem.update_all("grade_gategory_id = #{@mappings[key]}", ["course_id = ? and grade_category_id = ?", @course_id, key])
    end
    
    instructors.each do |user|
      notify( "Upgraded all assignments in '#{course.title}' from generic grade categories to custom ones.  You can now edit grade categories from the instructor page.", user )
    end
  end
  
  def notify( text, user )
    notification = Notification.new
    notification.notification = text
    notification.user = user
    notification.link = nil
    notification.emailed = false
    notification.acknowledged = false
    notification.save
  end
  
end

# params
# course_id type mapping pairs
course_id = ARGV[0].to_i
type = ARGV[1]
  
upgrade = UpgradeGradeCategories.new( course_id, type, ARGV[2..-1] )
upgrade.execute
