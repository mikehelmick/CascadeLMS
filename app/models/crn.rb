class Crn < ActiveRecord::Base
  validates_presence_of :crn, :name
  validates_uniqueness_of :crn
  
  has_and_belongs_to_many :courses
  
  def to_s
    self.crn
  end
  
  def term_id
    range_by_char( self.crn, @app['crn_format'], 'T' )
  end
  
  def year
    range_by_char( self.crn, @app['crn_format'], 'Y' )
  end
  
  def full_term_id
    "#{year(self.crn)}#{term_id(self.crn)}"
  end
  
  def range_by_char( str, format, char )
    index_b = format.index(char)
    index_e = format.length - format.reverse.index(char )
    
    #puts index_b
    #puts index_e
    if index_b >= 0 && index_e >= 0 && index_e > index_b 
      str[index_b...index_e]
    else
      ''
    end
  end
  
  private :range_by_char
  
end
