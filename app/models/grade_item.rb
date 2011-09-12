class GradeItem < ActiveRecord::Base
  
  belongs_to :course
  belongs_to :grade_category
  
  has_many :grade_entries, :dependent => :destroy
  
  belongs_to :assignment
  
  validates_presence_of :name, :display_type
  validates_numericality_of :points
  
  COMPLETE = 'Completed / Not'.freeze
  PERCENTAGE = 'Percentage'.freeze
  SCORE = 'Score'.freeze
  
  SHOWN_TYPES = [
      [ SCORE, "s" ],
      [ PERCENTAGE, "p" ],
      [ COMPLETE, "c"]
    ].freeze
  
    def GradeItem.shown_type( type = SCORE )
      SHOWN_TYPES.each do |t| 
        if t[0].eql?(type)
          return t[1]
        end
      end

      return 's'
    end

  def export_name
    self.name.gsub(',',';')
  end
  
  def clone
    dup = GradeItem.new
    dup.name = self.name
    dup.date = self.date
    dup.points = self.points
    dup.display_type = self.display_type
    dup.visible = self.visible
    dup.grade_category_id = self.grade_category_id
    dup.course_id = self.course_id
    return dup
  end
  
end
