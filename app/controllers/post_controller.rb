class PostController < ApplicationController
  
  before_filter :ensure_logged_in

  def index
    redirect_to :controller => '/home', :course => nil, :action => nil, :id => nil
  end

  def view
    @item = Item.find(params[:id])
    return unless allowed_to_view_item(@user, @item)

    @breadcrumb = Breadcrumb.new()
    @breadcrumb.text = 'View Post'
    @title = @item.title
  end

  def aplus    
    @item = Item.find(params[:item])
    return unless allowed_to_view_item(@user, @item)
    @item, userApRec = Item.toggle_plus(@item, @user)

    render :layout => false
  end
end
