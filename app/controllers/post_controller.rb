class PostController < ApplicationController
  
  before_filter :ensure_logged_in

  def index
    redirect_to :controller => '/home', :course => nil, :action => nil, :id => nil
  end

  def view
    @item = Item.find(params[:id])
    return unless allowed_to_view_item(@user, @item)
    return unless comments_open(@item)

    @breadcrumb = Breadcrumb.new()
    @breadcrumb.text = 'View Post'
    @title = @item.title

    @item_comment = ItemComment.new
  end

  def comment
    @item = Item.find(params[:id])
    return unless allowed_to_view_item(@user, @item)

    @item_comment = ItemComment.new(params[:item_comment])
    @item_comment.user = session[:user]
    @item_comment.ip = session[:ip]
    @item = Item.add_comment(@item, @item_comment)
    
    redirect_to :action => 'view', :id => params[:id]
  end

  def aplus    
    @item = Item.find(params[:item])
    return unless allowed_to_view_item(@user, @item)
    @item, userApRec = Item.toggle_plus(@item, @user)

    render :layout => false
  end

  private
  def comments_open(item)
    unless item.enable_comments?
      flash[:notice] = "Comments have been disabled."
      redirect_to :controller => '/post', :action => 'view', :id => item.id, :class => nil, :assignment => nil
      return false
    end
    true
  end
end
