class ItemComment < ActiveRecord::Base
  belongs_to :item
  belongs_to :user

  before_save :transform_markup

  def transform_markup
	  self.body_html = HtmlEngine.apply_textile( self.body )
  end
  
  protected :transform_markup
end
