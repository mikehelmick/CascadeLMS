class UserTurninFile < ActiveRecord::Base
  belongs_to :user_turnin
  acts_as_list :scope => :user_turnin
  
  def icon()
    if ( self.directory_entry )
      "folder"
    elsif ( self.extension.nil? )
      "page"
    else
      FileManager.icon( self.extension )
    end
  end
  
end
