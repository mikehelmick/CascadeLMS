class IoCheck < ActiveRecord::Base
  
  validates_presence_of :name
  validates_uniqueness_of :name, :scope => [:assignment_id]
  
  belongs_to :assignment
  
  def before_save
    self.input.gsub!(/\r\n/, "\n" ) rescue self.input = ''
    self.output.gsub!(/\r\n/, "\n" ) rescue self.output = ''
  end
  
end
