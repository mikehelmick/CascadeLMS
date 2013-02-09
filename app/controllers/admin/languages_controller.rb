class Admin::LanguagesController < ApplicationController
  
  before_filter :ensure_logged_in, :ensure_admin
  before_filter :set_tab
  
  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
    @programming_languages = ProgrammingLanguage.find(:all)
  end

  def show
    @programming_language = ProgrammingLanguage.find(params[:id])
    @breadcrumb.text = 'Details'
  end

  def new
    @programming_language = ProgrammingLanguage.new
  end

  def create
    @programming_language = ProgrammingLanguage.new(params[:programming_language])
    if @programming_language.save
      flash[:notice] = 'ProgrammingLanguage was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @programming_language = ProgrammingLanguage.find(params[:id])
    @breadcrumb.text = 'Edit Language'
  end

  def update
    @programming_language = ProgrammingLanguage.find(params[:id])
    if @programming_language.update_attributes(params[:programming_language])
      flash[:notice] = 'ProgrammingLanguage was successfully updated.'
      redirect_to :action => 'list'
    else
      render :action => 'edit'
    end
  end

  def destroy
    ProgrammingLanguage.find(params[:id]).destroy
    redirect_to :action => 'list'
  end
  
  def set_tab 
    @title = 'Programming Languages'
    @tab = 'administration'
    @breadcrumb = Breadcrumb.for_admin()
    @breadcrumb.admin_languages = true
  end
  
  private :set_tab
end
