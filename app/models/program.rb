class Program < ActiveRecord::Base
  
  has_many :programs_users
  has_many :users, :through => :programs_users

  has_many :program_outcomes, :order => "position", :dependent => :destroy

  has_and_belongs_to_many :courses
  has_and_belongs_to_many :course_templates
  
  def managers
    managers = Array.new   
    self.programs_users.each do |i|
      managers << i.user if i.program_manager
    end
    return managers
  end
  
  def auditors
    auditors = Array.new    
    self.programs_users.each do |i|
      auditors << i.user if i.program_auditor
    end
    return auditors   
  end

  def count_courses_in_term(term)
    Course.count_by_sql(["select * from courses left join (courses_programs) on (courses.id = courses_programs.course_id) where courses.term_id = ? and courses_programs.program_id = ? order by title asc;", term.id, self.id])
  end

  def courses_in_term(term)
    Course.find_by_sql(["select * from courses left join (courses_programs) on (courses.id = courses_programs.course_id) where courses.term_id = ? and courses_programs.program_id = ? order by title asc;", term.id, self.id])
  end
end
