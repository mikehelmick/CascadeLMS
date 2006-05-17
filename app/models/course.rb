class Course < ActiveRecord::Base
  validates_presence_of :title
  
  belongs_to :term
  has_and_belongs_to_many :crns
  has_and_belongs_to_many :users
  
  def open_text
    return 'Yes' if self.open
    return 'No'
  end
  
  def toggle_open
    self.open = ! self.open
  end
  
  def students
    inst = Array.new
    self.users.each do |u|
      inst << u if u.course_student.to_i > 0
    end
    inst    
  end
  
  def assistants
    inst = Array.new
    self.users.each do |u|
      inst << u if u.course_assistant.to_i > 0
    end
    inst    
  end
  
  def guests
    inst = Array.new
    self.users.each do |u|
      inst << u if u.course_guest.to_i > 0
    end
    inst   
  end
  
  def instructors
    inst = Array.new
    self.users.each do |u|
      inst << u if u.course_instructor.to_i > 0
    end
    inst
  end
  
end
