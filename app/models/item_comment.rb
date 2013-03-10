class ItemComment < ActiveRecord::Base
  belongs_to :item
  belongs_to :user

  before_save :transform_markup

  def transform_markup
	  self.body_html = self.body.apply_markup()
  end
  
  protected :transform_markup
end
