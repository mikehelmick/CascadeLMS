class PostController < ApplicationController
  
  before_filter :ensure_logged_in

  def aplus
    @item = Item.find(params[:item])
    @item, userApRec = Item.toggle_plus(@item, @user)

    render :layout => false
  end
  
end
