class APlus < ActiveRecord::Base
  belongs_to :item
  belongs_to :user

  def self.for(item, user)
    ap = APlus.new
    ap.item = item
    ap.user = user
    ap.save
    return ap
  end
end
