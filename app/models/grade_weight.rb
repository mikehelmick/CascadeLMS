class GradeWeight < ActiveRecord::Base
  
  belongs_to :gradebook
  belongs_to :grade_category
  
  def GradeWeight.reconcile( course )
    categories = GradeCategory.for_course( course )
    # get categories
    
    weights = GradeWeight.find( :all, :conditions => ["gradebook_id=?", course.id] )
    total = 0
    
    to_create = Array.new
    categories.each do |cat|
      found = false
      weights.each do |weight|
        if weight.grade_category_id == cat.id
          found = true
          total = total + weight.percentage
        end
      end
      
      if ! found
        weight = GradeWeight.new
        weight.grade_category = cat
        weight.percentage = 0
        weight.gradebook_id = course.id
        to_create << weight
      end
    end
    
    if ( total < 100 ) 
      if ( to_create.size > 0 )
        to_create[0].percentage = sprintf("%.2f", 100 - total ).to_f
      elsif ( weights.size > 0 )
        weights[0].percentage = weights[0].percentage + sprintf("%.2f", 100 - total ).to_f
      end
    end

    GradeWeight.transaction do
      to_create.each do |x|
        x.save
        weights << x
      end
    end
    
    return weights
  end
  
end
