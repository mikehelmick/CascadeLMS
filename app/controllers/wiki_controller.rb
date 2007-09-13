class WikiController < ApplicationController
  
  before_filter :ensure_logged_in
  before_filter :set_tab
  
  @@range0 = ('A'..'Z').freeze
  @@range1 = ('a'..'z').freeze
  @@range2 = ('0'..'9').freeze
  
  def index
    redirect_to :action => 'page', :course => params[:course], :id => 'Home'
  end
  
  def page
    return unless load_course( params[:course] )
    return unless allowed_to_see_course( @course, @user )
    return unless wiki_enabled( @course )   
    
    page = params[:id]
    return unless valid_wiki_page_name( @course, page ) 
    
    
    @page = Wiki.find_or_create( @course, @user, page ) 
    
    @page.content_html = wiki_links( @page.content_html, @course )
    
    wiki_title   
  end
  
  
  def edit
    return unless load_course( params[:course] )
    return unless allowed_to_see_course( @course, @user )
    return unless wiki_enabled( @course )  
    return unless valid_wiki_page_name( @course, params[:id] )
    
    @page = Wiki.find(:first, :conditions => ["course_id = ? and page = ?", @course.id, params[:id] ], :order => "revision DESC") rescue @page = nil
    if @page.nil?
      flash[:badnotice] = "Wiki page '#{params[:id]}' could not be found."
      redirect_to :action => 'page', :id => 'Home'
    end
    @pg = @page
    wiki_title
  end
  
  def save
    return unless load_course( params[:course] )
    return unless allowed_to_see_course( @course, @user )
    return unless wiki_enabled( @course )  
    
    return unless valid_wiki_page_name( @course, params[:id] )
    
    @previous = Wiki.find(:first, :conditions => ["course_id = ? and page = ?", @course.id, params[:id] ], :order => "revision DESC") rescue @page = nil
    if @previous.nil?
      flash[:badnotice] = "Wiki page '#{params[:id]}' could not be found."
      redirect_to :action => 'page', :id => 'Home'
    end
    
    @pg = Wiki.new
    @pg.course_id = @course.id
    @pg.page = @previous.page
    @pg.content = params['pg']['content'] rescue @pg.content = ''
    @pg.user = @user
    @pg.revision = @previous.revision + 1
    
    if @pg.save
      flash[:notice] = "Page '#{@pg.page}' has been updated."
      redirect_to :action => 'page', :id => @pg.page
    else
      @page = @previous
      flash[:badnotice] = "There was an error updating this page."
      render :action => 'edit'
    end
    wiki_title
  end
  
  def history
    return unless load_course( params[:course] )
    return unless allowed_to_see_course( @course, @user )
    return unless wiki_enabled( @course )  
    
    return unless valid_wiki_page_name( @course, params[:id] )
    
    @pages = Wiki.find(:all, :conditions => ["course_id = ? and page = ?", @course.id, params[:id] ], :order => "revision DESC") rescue @pages = Array.new
    
    if @pages.size == 0 
      flash[:notice] = 'There is no history to display for this page.'
      redirect_to :action => 'page', :id => params[:id]
      
    else
      @page = @pages[0]
      
      @pages.each do |page|
        page.content_html = wiki_links( page.content_html, @course )
      end
      
    end
    wiki_title
  end
  
  def restore
    return unless load_course( params[:course] )
    return unless allowed_to_see_course( @course, @user )
    return unless wiki_enabled( @course )  
    
    return unless valid_wiki_page_name( @course, params[:id] )
    
    @cur_page = Wiki.find(:first, :conditions => ["course_id = ? and page = ?", @course.id, params[:id] ], :order => "revision DESC") rescue @cur_page = nil
    
    @old_page = Wiki.find(:first, :conditions => ["course_id = ? and page = ? and revision = ?", @course.id, params[:id], params['revision'].to_i ]) rescue @old_page = nil
    
    if @cur_page.nil? || @old_page.nil?
      flash[:badnotice] = "The selected revision could not be restored."
      redirect_to :action => 'history', :id => params['page']
      return
    end
    
    @pg = Wiki.new
    @pg.course_id = @course.id
    @pg.page = @cur_page.page
    @pg.content = @old_page.content
    @pg.user = @user
    @pg.revision = @cur_page.revision + 1
    @pg.save
    flash[:notice] = "The requested revision has been restored."
    
    redirect_to :action => 'page', :id => params[:id]
    wiki_title
  end
  
  def wikidex
    return unless load_course( params[:course] )
    return unless allowed_to_see_course( @course, @user )
    return unless wiki_enabled( @course )  
    
    pages = Wiki.find(:all, :conditions => ["course_id = ?", @course.id], :order => "page asc, revision DESC" ) 
    @pages = Array.new
    page_map = Hash.new
    
    pages.each do |page|
      if page_map[page.page].nil?
        page_map[page.page] = true
        @pages << page
      end
    end
    
    @pages.sort! { |a,b| a.page.downcase <=> b.page.downcase }
    wiki_title
  end
  
  private 
  
  def wiki_title
    @title = "Wiki #{@course.title}"
  end
  
  def set_tab
    @show_course_tabs = true
    @tab = 'course_wiki'
    @title = 'Course Wiki'
  end
  
  def wiki_enabled( course )
    unless @course.course_setting.enable_wiki
      flash[:notice] = "This course does not have a Wiki."
      redirect_to :controller => '/overview', :id => nil, :course => course
      return false
    end
    return true   
  end

  def wiki_links( html, course )
    regex = Regexp.new('\[[a-z|A-Z|0-9]*\]')
    
    match = regex.match( html )
    while( !match.nil? )
      build_link = match[0][1...-1]
      link = url_for( :controller => '/wiki', :action => 'page', :course => course.id, :id => build_link )
      html = html.sub( match[0], "<a href=\"#{link}\">#{build_link}</a>" )
      
      match = regex.match( html )
    end
    
    return html
  end
  
  def valid_wiki_page_name( course, name )
    contains_all = true
    0.upto(name.length-1) do |i|
      sub = name[i..i]
      unless @@range0.member?(sub) || @@range1.member?(sub) || @@range2.member?(sub)
        contains_all = false
      end
    end
    
    unless contains_all
      flash[:notice] = "Invalid wiki page name, only A..Z,a..z,0..9 are allowed in wiki page names."
      redirect_to :action => 'page', :id => 'Home'
      return false
    end
    return true
  end
  
end
