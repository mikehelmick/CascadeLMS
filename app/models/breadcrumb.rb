class Breadcrumb
  
  # team is studnet view
  # teams is instructor view
  attr_accessor :course, :assignment, :document, :forum, :post, :team, :wiki
  attr_accessor :instructor, :program, :outcomes, :gradebook, :teams, :attendance
  # text to display at the end
  attr_accessor :text, :link

  def initialize(course = nil, instructor = false)
    @course = course
    @instructor = instructor
    self.outcomes = false
    self.gradebook = false
  end

  def self.for_program(program)
    b = Breadcrumb.new()
    b.program = program
    return b
  end

  def self.for_course(course, instructor = false)
    Breadcrumb.new(course, instructor)
  end

  def self.for_assignment(assignment, instructor = false)
    obj = Breadcrumb.new(assignment.course, instructor)
    obj.assignment = assignment
    return obj
  end

  def self.for_document(document)
    obj = Breadcrumb.new(document.course)
    obj.document = document
    return obj
  end

  def self.for_forum(forum)
    obj = Breadcrumb.new(forum.course)
    obj.forum = forum
    return obj
  end

  def self.for_post(post)
    obj = Breadcrumb.new(post.course)
    obj.post = post
    return obj
  end
end