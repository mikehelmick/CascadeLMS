class Admin::SettingsController < ApplicationController

  before_filter :ensure_logged_in, :ensure_admin
  # don't set on the AJAX calls
  before_filter :set_tab

  def index
    @settings = Setting.find(:all, :order => 'name asc')
    @breadcrumb = Breadcrumb.for_admin()
    @breadcrumb.text = 'Application Settings'
  end
  
  def update    
    @setting = Setting.find( params[:id] )

    unless @setting.nil?
      @setting.value = params[:value]
      @setting.save
    end

    ApplicationController.app(true)
    render :layout => false
  end

  private
  def set_tab
    @title = 'Application Settings'
    @tab = 'administration'
  end
end
