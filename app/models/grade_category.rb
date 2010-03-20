class GradeCategory < ActiveRecord::Base
  
  validates_presence_of :category
  
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
