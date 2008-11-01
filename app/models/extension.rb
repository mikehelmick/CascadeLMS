class Extension < ActiveRecord::Base

  belongs_to :assignment
  belongs_to :user

  def past?
    Time.now > extension_date
  end

end
