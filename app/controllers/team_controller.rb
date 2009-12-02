class TeamController < ApplicationController
  
  before_filter :ensure_logged_in
  before_filter :set_tab
  
  @@range0 = ('A'..'Z').freeze
  @@range1 = ('a'..'z').freeze
  @@range2 = ('0'..'9').freeze
  
  def index
    return unless load_course( params[:course] )
    return unless allowed_to_see_course( @course, @user )
    return unless teams_enabled( @course )
    
    @team = TeamMember.find(:first, :conditions => ["course_id = ? and user_id = ?", @course.id, @user.id]).project_team rescue @team = nil
  
    @all_teams = nil
    if @user.instructor_in_course?( @course.id )
      @all_teams = ProjectTeam.find(:all, :conditions => ["course_id = ?", @course.id] )
    end
  end
  
  #### WIKI
  def wiki
    return unless load_course( params[:course] )
    return unless allowed_to_see_course( @course, @user )
    return unless teams_enabled( @course )    
    
    @team = ProjectTeam.find( params[:id] )
    return unless on_team_or_instructor( @course, @team, @user )
    return unless team_enable_wiki( @course )
    return unless valid_wiki_page_name( @team, params['page'] )
    
    @page = TeamWikiPage.find_or_create( @team, @user, params['page'] ) 
    
    @page.content_html = wiki_links( @page.content_html, @team, @course )
    
    wiki_title
  end
  
  def wikidex
    return unless load_course( params[:course] )
    return unless allowed_to_see_course( @course, @user )
    return unless teams_enabled( @course )    
    
    @team = ProjectTeam.find( params[:id] )
    return unless on_team_or_instructor( @course, @team, @user )
    return unless team_enable_wiki( @course )
    
    pages = TeamWikiPage.find(:all, :conditions => ["project_team_id = ?", @team.id], :order => "page asc, revision DESC" ) 
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
  
  def wikipast
    return unless load_course( params[:course] )
    return unless allowed_to_see_course( @course, @user )
    return unless teams_enabled( @course )    
    
    @team = ProjectTeam.find( params[:id] )
    return unless on_team_or_instructor( @course, @team, @user )
    return unless team_enable_wiki( @course )
    return unless valid_wiki_page_name( @team, params['page'] )
    
    @pages = TeamWikiPage.find(:all, :conditions => ["project_team_id = ? and page = ?", @team.id, params['page'] ], :order => "revision DESC") rescue @pages = Array.new
    
    if @pages.size == 0 
      flash[:notice] = 'There is no history to display for this page.'
      redirect_to :action => 'index', :id => @team, :page => @page_name
      
    else
      @page = @pages[0]
      
      @pages.each do |page|
        page.content_html = wiki_links( page.content_html, @team, @course )
      end
      
    end
    wiki_title
  end
  
  def wikiedit
    return unless load_course( params[:course] )
    return unless allowed_to_see_course( @course, @user )
    return unless teams_enabled( @course )    
    
    @team = ProjectTeam.find( params[:id] )
    return unless on_team_or_instructor( @course, @team, @user )
    return unless team_enable_wiki( @course )
    return unless valid_wiki_page_name( @team, params['page'] )
    
    @page = TeamWikiPage.find(:first, :conditions => ["project_team_id = ? and page = ?", @team.id, params['page'] ], :order => "revision DESC") rescue @page = nil
    if @page.nil?
      flash[:badnotice] = "Wiki page '#{params['page']}' could not be found."
      redirect_to :action => 'wiki', :id => @team, :page => 'Home'
    end
    @pg = @page
    wiki_title
  end
  
  def wikisave
    return unless load_course( params[:course] )
    return unless allowed_to_see_course( @course, @user )
    return unless teams_enabled( @course )    
    
    @team = ProjectTeam.find( params[:id] )
    return unless on_team_or_instructor( @course, @team, @user )
    return unless team_enable_wiki( @course )
    return unless valid_wiki_page_name( @team, params['page'] )
    
    @previous = TeamWikiPage.find(:first, :conditions => ["project_team_id = ? and page = ?", @team.id, params['page'] ], :order => "revision DESC") rescue @page = nil
    if @previous.nil?
      flash[:badnotice] = "Wiki page '#{params['page']}' could not be found."
      redirect_to :action => 'wiki', :id => @team, :page => 'Home'
    end
    
    @pg = TeamWikiPage.new
    @pg.project_team_id = @previous.project_team_id
    @pg.page = @previous.page
    @pg.content = params['pg']['content']
    @pg.user = @user
    @pg.revision = @previous.revision + 1
    
    if @pg.save
      flash[:notice] = "Page '#{@pg.page}' has been updated."
      redirect_to :action => 'wiki', :id => @team, :page => @pg.page
    else
      @page = @previous
      flash[:badnotice] = "There was an error updating this page."
      render :action => 'wikiedit'
    end
    wiki_title
  end
  
  def wikirestore
    return unless load_course( params[:course] )
    return unless allowed_to_see_course( @course, @user )
    return unless teams_enabled( @course )    
    
    @team = ProjectTeam.find( params[:id] )
    return unless on_team_or_instructor( @course, @team, @user )
    return unless team_enable_wiki( @course )
    return unless valid_wiki_page_name( @team, params['page'] )
    
    @cur_page = TeamWikiPage.find(:first, :conditions => ["project_team_id = ? and page = ?", @team.id, params['page'] ], :order => "revision DESC") rescue @cur_page = nil
    
    @old_page = TeamWikiPage.find(:first, :conditions => ["project_team_id = ? and page = ? and revision = ?", @team.id, params['page'], params['revision'].to_i ]) rescue @old_page = nil
    
    if @cur_page.nil? || @old_page.nil?
      flash[:badnotice] = "The selected revision could not be restored."
      redirect_to :action => 'wikipast', :id => @team, :page => params['page']
      return
    end
    
    @pg = TeamWikiPage.new
    @pg.project_team_id = @cur_page.project_team_id
    @pg.page = @cur_page.page
    @pg.content = @old_page.content
    @pg.user = @user
    @pg.revision = @cur_page.revision + 1
    @pg.save
    flash[:notice] = "The requested revision has been restored."
    
    redirect_to :action => 'wiki', :id => @team, :page => params['page']
    wiki_title
  end
  
  ### Team email
  def email
    return unless load_course( params[:course] )
    return unless allowed_to_see_course( @course, @user )
    return unless teams_enabled( @course )  
    @team = ProjectTeam.find( params[:id] )
    return unless on_team_or_instructor( @course, @team, @user )  
    return unless team_enable_email( @course )
   
    @page = params[:page].to_i
    @page = 1 if @page.nil? || @page == 0
    @email_pages = Paginator.new self, TeamEmail.count(:conditions => ["project_team_id = ?", @team.id ]), 50, @page
    @emails = TeamEmail.find(:all, :conditions => ["project_team_id = ?", @team.id ], :order => 'created_at DESC', :limit => 50, :offset => @email_pages.current.offset)
    
    @title = "Team email archive, team '#{@team.name}' in #{@course.title}" 
  end
  
  def email_read
    return unless load_course( params[:course] )
    return unless allowed_to_see_course( @course, @user )
    return unless teams_enabled( @course )  
    @team = ProjectTeam.find( params[:id] )
    return unless on_team_or_instructor( @course, @team, @user )
    return unless team_enable_email( @course )
    
    @email = TeamEmail.find(:first, :conditions => ["project_team_id = ? and id = ?", @team.id, params['email'].to_i ] ) rescue @email = nil
    
    if @email.nil?
      flash[:badnotice] = "Invalid email requested."
      redirect_to :action => 'email', :id => @team, :email => nil
      return
    end
        
  end
  
  def email_compose
    return unless load_course( params[:course] )
    return unless allowed_to_see_course( @course, @user )
    return unless teams_enabled( @course )  
    @team = ProjectTeam.find( params[:id] )
    return unless on_team_or_instructor( @course, @team, @user )
    return unless team_enable_email( @course )
    
    @email = TeamEmail.new  
  end

  def email_send
    return unless load_course( params[:course] )
    return unless allowed_to_see_course( @course, @user )
    return unless teams_enabled( @course )  
    @team = ProjectTeam.find( params[:id] )
    return unless on_team_or_instructor( @course, @team, @user )
    return unless team_enable_email( @course )
    
    send_users = Array.new
    @team.team_members do |tm|
      send_users << tm.user.email
    end
    
    @email = TeamEmail.new(params[:email])
    @email.project_team = @team
    @email.user = @user
    
    if !@email.save
      render :action => 'email_compose'
      return
    end
    
    Notifier::deliver_send_email( send_users, @email.message, @email.subject, @user )
   
    flash[:notice] = 'Email delivered to selected users.'    
    
    redirect_to :action => 'email', :id => @team
  end
  
  
  ## deam documents
  def files
    return unless load_course( params[:course] )
    return unless allowed_to_see_course( @course, @user )
    return unless teams_enabled( @course )  
    @team = ProjectTeam.find( params[:id] )
    return unless on_team_or_instructor( @course, @team, @user )
    return unless team_enable_documents( @course )
      
    @documents = TeamDocument.find(:all, :conditions => ["project_team_id = ?", @team.id], :order => "created_at DESC")  
  end
  
  def file_new
    return unless load_course( params[:course] )
    return unless allowed_to_see_course( @course, @user )
    return unless teams_enabled( @course )  
    @team = ProjectTeam.find( params[:id] )
    return unless on_team_or_instructor( @course, @team, @user )
    return unless team_enable_documents( @course )    
    return unless instructor_documents_filter( @course, @user )
    
    @document = TeamDocument.new  
  end
  
  def file_upload
    return unless load_course( params[:course] )
    return unless allowed_to_see_course( @course, @user )
    return unless teams_enabled( @course )  
    @team = ProjectTeam.find( params[:id] )
    return unless on_team_or_instructor( @course, @team, @user )
    return unless team_enable_documents( @course )    
    return unless instructor_documents_filter( @course, @user )
    
    
    @document = TeamDocument.new
    @document.project_team = @team
    @document.user = @user
    @document.set_file_props( params[:file] ) unless params[:file].class.to_s.eql?('String')
    
    if @document.save
      @document.create_file( params[:file], @app['external_dir'] )
        
      flash[:notice] = 'Document was successfully created.'
      redirect_to :action => 'files', :id => @team.id
    else
      render :action => 'file_new'
    end
  end
  
  def download
    return unless load_course( params[:course] )
    return unless allowed_to_see_course( @course, @user )
    return unless teams_enabled( @course )  
    @team = ProjectTeam.find( params[:id] )
    return unless on_team_or_instructor( @course, @team, @user )
    return unless team_enable_documents( @course )    
    return unless instructor_documents_filter( @course, @user )
    
    
    @document = TeamDocument.find(:first, :conditions => ["project_team_id = ? and id = ?", @team.id, params['document'].to_i ] ) rescue @document = nil
    
    if @document.nil?
      flash[:badnotice] = "Invalid document requested."
      redirect_to :action => 'files', :id => @team, :document => nil
      return
    end
    
    begin  
      send_file @document.resolve_file_name(@app['external_dir']), :filename => @document.filename, :type => "#{@document.content_type}", :disposition => 'inline'  
    rescue
      flash[:badnotice] = "Sorry - the requested document has been deleted or is corrupt.  Please notify your instructor of the problem and mention 'team document id #{@document.id}'."
      redirect_to :action => 'files', :id => @team.id
    end
    
  end
  
  private
  
  def wiki_title
    @title = "Wiki for team #{@team.name} in #{@course.title}"
  end
  
  def wiki_links( html, team, course )
    regex = Regexp.new('\[[a-z|A-Z|0-9]*\]')
    
    match = regex.match( html )
    while( !match.nil? )
      build_link = match[0][1...-1]
      link = url_for( :controller => '/team', :action => 'wiki', :id => team.id, :course => course.id, :page => build_link )
      html = html.sub( match[0], "<a href=\"#{link}\">#{build_link}</a>" )
      
      match = regex.match( html )
    end
    
    return html
  end
  
  def set_tab
    @show_course_tabs = true
    @tab = 'course_teams'
    @title = 'Team Center'
  end
  
  def valid_wiki_page_name( team, name )
    contains_all = true
    0.upto(name.length-1) do |i|
      sub = name[i..i]
      unless @@range0.member?(sub) || @@range1.member?(sub) || @@range2.member?(sub)
        contains_all = false
      end
    end
    
    unless contains_all
      flash[:notice] = "Invalid wiki page name, only A..Z,a..z,0..9 are allowed in wiki page names."
      redirect_to :action => 'wiki', :id => team.id, :page => 'home'
      return false
    end
    return true
  end
  
  def instructor_documents_filter( course, user )
    if course.course_setting.team_documents_instructor_upload_only && ! user.instructor_in_course?( course.id ) 
      flash[:notice] = "Only the instructor may upload documents."
      redirect_to :action => 'index', :id => nil
      return false
    end
    return true
  end
  
  def on_team_or_instructor( course, team, user )
    unless user.instructor_in_course?( course.id ) || team.on_team?( user )
      flash[:notice] = "Invalid project team requested."
      redirect_to :action => 'index', :id => nil
      return false
    end
    return true
  end
  
  def team_enable_wiki( course )
    unless course.course_setting.team_enable_wiki
      flash[:badnotice] = "Team wikis are not enabled."
      redirect_to :action => 'index', :id => nil
      return false
    end
    return true
  end
  
  def team_enable_email( course )
    unless course.course_setting.team_enable_email
      flash[:badnotice] = "Team email is not enabled."
      redirect_to :action => 'index', :id => nil
      return false
    end
    return true
  end  
  
  def team_enable_documents( course )
    unless course.course_setting.team_enable_documents
      flash[:badnotice] = "Team documents are not enabled."
      redirect_to :action => 'index', :id => nil
      return false
    end
    return true
  end
  
  def team_documents_instructor_upload_only( course )
    unless course.course_setting.team_documents_instructor_upload_only
      flash[:badnotice] = "Team documents uploads are not enabled."
      redirect_to :action => 'index', :id => nil
      return false
    end
    return true
  end
  
  def teams_enabled( course )
    unless course.course_setting.enable_project_teams
      flash[:badnotice] = "Project teams are not enabled for this course."
      redirect_to :controller => '/instructor/index', :course => course
      return false
    end
    return true
  end
  
end
