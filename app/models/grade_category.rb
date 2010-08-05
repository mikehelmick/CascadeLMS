class GradeCategory < ActiveRecord::Base
  
  validates_presence_of :category
  
  ## Ensures that the categories in the first course are a superset
  ## of the second course
  ##
  ## returns a map, mapping IDs from the second course to the first
  def GradeCategory.ensure_super_set_of( course, otherCourse )
    my_categories = GradeCategory.for_course(course)
    my_map = Hash.new
    my_categories.each do |cat|
      my_map[cat.category] = cat.id
    end
    
    other_categories = GradeCategory.for_course(otherCourse)
    other_categories.each do |cat|
      if !my_map[cat.category]
        newCategory = GradeCategory.new
        newCategory.category = cat.category
        newCategory.course_id = course.id
        newCategory.save
      end
    end
    
    category_map = Hash.new
    other_categories.each do |cat|
      category_map[cat.id] = my_map[cat.category]
    end
    
    return category_map
  end
  
  def GradeCategory.for_course( course )
    categories = GradeCategory.find(:all, :conditions => ["course_id = ?", course.id], :order => 'category asc')
    if categories.length == 0 
      categories = Array.new
      
      GradeCategory.transaction do
        mappings = Hash.new
        # initialize from default
        default = GradeCategory.find(:all, :conditions => ["course_id = ?", 0], :order => 'category asc')
        default.each do |defaultCategory|
          newCategory = GradeCategory.new
          newCategory.category = defaultCategory.category
          newCategory.course_id = course.id
          newCategory.save
          categories << newCategory

          mappings[defaultCategory.id] = newCategory.id
        end

        mappings.keys.each do |key|
          # update assignments for this mapping
          Assignment.update_all("grade_category_id = #{mappings[key]}", ["course_id = ? and grade_category_id = ?", course.id, key])

          # update grade_items for this mapping
          GradeItem.update_all("grade_category_id = #{mappings[key]}", ["course_id = ? and grade_category_id = ?", course.id, key])
        end
      end
          
    end
    return categories
  end
  
end
