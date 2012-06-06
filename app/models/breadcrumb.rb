class Breadcrumb
  
  attr_accessor :course, :assignment, :document, :forum, :post, :team, :wiki
  # text to display at the end
  attr_accessor :text, :link

  def initialize(course = nil)
    @course = course
  end

  def self.for_course(course)
    Breadcrumb.new(course)
  end

  def self.for_assignment(assignment)
    obj = Breadcrumb.new(assignment.course)
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