class UserTurnin < ActiveRecord::Base
  belongs_to :assignment
  belongs_to :user
  acts_as_list :scope => :user
  
  has_many :user_turnin_files, :order => "position asc", :dependent => :destroy
  
  def get_dir( dir )
    "#{dir}/term/#{assignment.course.term.id}/course/#{assignment.course.id}/turnins/#{user.uniqueid}/assignment_#{assignment.id}/turnin_#{self.id}"  
  end
  
  def make_sub_dir( dir, chain ) 
    fs_path = "#{get_dir( dir )}/#{chain}"
    FileUtils.mkdir_p( fs_path )
  end
    
  def make_dir( dir )
    fs_path = get_dir(dir)
    FileUtils.mkdir_p( fs_path )
  end
  
  def delete_dir( dir ) 
    fs_path = get_dir( dir )
    FileUtils.remove_dir( fs_path, true )
  end
  
end
