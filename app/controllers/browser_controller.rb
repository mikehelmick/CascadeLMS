class BrowserController < ApplicationController
  
  layout 'login'
  
  def index    
    @user = User.new
    cookies[:ie_override] = nil
  end
  
  def approve
    cookies[:ie_override] = true.to_s
    redirect_to :controller => '/index'
  end
  
end
