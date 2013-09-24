class Admin::GithubController < ApplicationController
  before_filter :ensure_logged_in, :ensure_admin
  before_filter :set_tab

  def index
    @servers = GithubServer.find(:all, :order => 'name asc')
    @breadcrumb.text = 'Github Servers'
  end

  def new
    @github_server = GithubServer.new
    @github_server.set_defaults 
    puts @github_server.inspect
    @breadcrumb.text = 'New Github Server'
  end

  def create
    @github_server = GithubServer.new(params[:github_server])
    if @github_server.save
      flash[:notice] = 'Github Server was successfully created.'
      redirect_to :action => 'index'
    else
      render :action => 'new'
    end
  end

  def toggle_active
    @github_server = GithubServer.find(params[:id])
    @github_server.active = !@github_server.active
    @github_server.save

    flash[:notice] = "Settings saved for server '#{@github_server.name}'"
    redirect_to :action => 'index'
  end

  def edit
    @github_server = GithubServer.find(params[:id])
    @breadcrumb.text = 'Edit Github Server'
  end

  def update
    @github_server = GithubServer.find(params[:id])
    if @github_server.update_attributes(params[:github_server])
      flash[:notice] = "Github Server settings for '#{@github_server.name}' were successfully updated."
      redirect_to :action => 'index'
    else
      render :action => 'edit'
    end
  end
  
  private
  def set_tab()
    @title = 'Remote Github Server Settings'
    @breadcrumb = Breadcrumb.for_admin()
    @tab = 'administration'
  end
end
