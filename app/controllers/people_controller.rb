class PeopleController < ApplicationController
  before_filter :ensure_logged_in
  
  def search
    st = params[:searchterms].downcase
    if st.length >= 3
      sv = "%#{st}%"
      @users = User.find(:all, :conditions => ["LOWER(uniqueid) like ? or LOWER(first_name) like ? or LOWER(last_name) like ? or LOWER(preferred_name) like ?", sv, sv, sv, sv ], :order => "uniqueid asc")
    else
      @users = Array.new
      @invalid = true
    end

    @breadcrumb = Breadcrumb.new()
    @breadcrumb.text = 'Find People'
  end
end
