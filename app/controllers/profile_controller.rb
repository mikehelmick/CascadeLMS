class ProfileController < ApplicationController
  before_filter :ensure_logged_in

  def index
    redirect_to :controller => '/home', :action => nil, :id => nil, :course => nil
  end

  def view
    
  end
end
