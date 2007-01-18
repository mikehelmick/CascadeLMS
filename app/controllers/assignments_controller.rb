require 'SubversionManager'
require 'auto_grade_helper'

class AssignmentsController < ApplicationController
  
  before_filter :ensure_logged_in
  before_filter :set_tab, :except => [ :svn_command ]

  def index
    return unless load_course( params[:course] )
    return unless allowed_to_see_course( @course, @user )

    set_title
  end
  
  def view
    return unless load_course( params[:course] )
    return unless allowed_to_see_course( @course, @user )
    
    @assignment = Assignment.find(params[:id]) rescue @assignment = Assignment.new
    return unless assignment_in_course( @assignment, @course )
    return unless assignment_available( @assignment )
    
    if @assignment.use_subversion && @assignment.auto_grade
      count_todays_turnins( @app["turnin_limit"].to_i )
    end
    
    if @assignment.enable_journal
      @journals = @user.assignment_journals( @assignment )
      
      if @assignment.journal_field.start_time && @assignment.journal_field.end_time
        elapsed = 0;
        @journals.each do |journal|
          interruption = journal.interruption_time
          interruption = 0 if interruption.nil?
          elapsed += journal.end_time - journal.start_time - interruption*60
        end
        elapsed = (elapsed / 60).truncate #down to minutes
        @minutes = elapsed % 60
        elapsed -= @minutes

        @days = (elapsed / 1440).truncate
        elapsed -= @days * 1440

        @hours = (elapsed / 60).truncate
      end
    end
    
    @now = Time.now
    set_title
  end

  def download
    return unless load_course( params[:course] )
    return unless allowed_to_see_course( @course, @user )
    
    @assignment = Assignment.find(params[:id]) rescue @assignment = Assignment.new
    return unless assignment_in_course( @assignment, @course )
    return unless assignment_available( @assignment )
    
    @document = AssignmentDocument.find(params[:document]) rescue @document = AssignmentDocument.new
    return unless document_in_assignment( @document, @assignment )
       
       
    begin  
      send_file @document.resolve_file_name(@app['external_dir']), :filename => @document.filename, :type => "#{@document.content_type}", :disposition => 'inline'  
    rescue
      flash[:badnotice] = "Sorry - the requested document has been deleted or is corrupt.  Please notify your instructor of the problem and mention 'assignment document id #{@document.id}'."
      redirect_to :action => 'view', :assignment => @assignment, :course => @course
    end 
  end

  def svn_command
    
    @partial_name = nil
    
    exit = false
    return render( :layout => false ) unless load_course( params[:course], false )
    return render( :layout => false ) unless allowed_to_see_course( @course, @user, false )
    
    @assignment = Assignment.find(params[:id]) rescue @assignment = Assignment.new
    return render( :layout => false ) unless assignment_in_course( @assignment, @course )
    return render( :layout => false ) unless assignment_available( @assignment )
    
    if params[:password].nil? || params[:password].size == 0 
      flash[:badnotice] = "You must enter your password."
      sleep( 0.5 )
      return render( :layout => false )
    end
    
    if params[:command].eql?('list_dev') || params[:command].eql?('list_rel')
      
      path = @assignment.development_path_replace(@user.uniqueid)
      path = @assignment.release_path_replace(@user.uniqueid) if params[:command].eql?('list_rel')
      
      svn = SubversionManager.new( @app['subversion_command'] )
      svn.logger = logger
      begin
        @list_entries = svn.list( @user.uniqueid, params[:password], @assignment.subversion_server, path )  
        @path = "#{path}"
        render :layout => false, :partial => 'svnlist'
      rescue RuntimeError => re
        flash[:badnotice] = re.message
        render :layout => false
      end
      
    elsif params[:command].eql?('create_dev')
      svn = SubversionManager.new( @app['subversion_command'] )
      svn.logger = logger
      begin
        flash[:notice] = svn.create_directory( @user.uniqueid, params[:password], @assignment.subversion_server, @assignment.development_path_replace(@user.uniqueid) )
        @list_entries = svn.list( @user.uniqueid, params[:password], @assignment.subversion_server, @assignment.development_path_replace(@user.uniqueid) )  
        @path = "#{@assignment.development_path_replace(@user.uniqueid)}"
        render :layout => false, :partial => 'svnlist'
      rescue RuntimeError => re
        flash[:badnotice] = re.message
        render :layout => false
      end
    
    elsif params[:command].eql?('release') || params[:command].eql?('turnin')
      return unless assignment_open( @assignment )
      return unless course_open( @course, :action => 'index' )
      
      svn = SubversionManager.new( @app['subversion_command'] )
      svn.logger = logger
      begin
        output = ""
        if params[:command].eql?('release')
          output = svn.create_release( @user.uniqueid, params[:password], @assignment.subversion_server, @assignment.development_path_replace(@user.uniqueid), @assignment.release_path_replace(@user.uniqueid) )  
        end
        
        path = @assignment.release_path_replace(@user.uniqueid)
        
        @turnins = UserTurnin.find( :all, :conditions => [ "assignment_id = ? and user_id = ?", @assignment.id, @user.id ], :order => "position desc" )
        @current_turnin = nil
        @current_turnin = @turnins[0] if @turnins.size > 0
        if @current_turnin
          if ! @current_turnin.sealed
            @current_turnin.sealed = true
            @current_turnin.save
          end
        end
        
        ut = UserTurnin.new
        ut.assignment = @assignment
        ut.user = @user
        ut.sealed = false
        @user.user_turnins << ut
        @user.save
        
        ut.make_dir( @app['external_dir'] )
        
        @list_entries = svn.get_release_files( @user.uniqueid, params[:password], @assignment.subversion_server, path, ut.get_dir( @app['external_dir'] ) )
       
        # create root entry
        utf = UserTurninFile.new
        utf.user_turnin = ut
        utf.directory_entry = true
        utf.directory_parent = 0
        utf.filename = '/'
        ut.user_turnin_files << utf
        ut.save
        
        first_parent = utf.id
        
        parent = utf.id
        take_off = ''
        ## create entries in database
        @list_entries.each do |le|
          utf = UserTurninFile.new
          utf.user_turnin = ut
          utf.directory_entry = le.dir?
          
          if ( le.dir? )
            # see if this has the same prefix ("subdir")
            unless ( le.name.to_s.index( take_off ).nil? )
              utf.filename = le.name.to_s[take_off.size...le.name.to_s.size]
              
              utf.directory_parent = parent
              take_off = "#{take_off}#{utf.filename}/"
            else
              # back up to parent level
              utf.filename = le.name.to_s
              utf.directory_parent = first_parent
              take_off = "#{utf.filename}/"
            end
          else
            utf.directory_parent = parent
            utf.filename = le.name.to_s[take_off.size...le.name.to_s.size]
          end
          
          ridx = utf.filename.to_s.rindex('.')
          unless ridx.nil?
            utf.extension = utf.filename[(ridx+1)...utf.filename.size]
          end
          ut.user_turnin_files << utf
          
          if utf.directory_entry
            parent = utf.id
          end
          
          mover = UserTurninFile.get_parent( ut.user_turnin_files, utf )
          fname = utf.filename
          while( mover.directory_parent > 0 )
            fname = UserTurninFile.prepend_dir( mover.filename, fname )
            mover = UserTurninFile.get_parent( ut.user_turnin_files, mover )
          end
          dir_name = "#{ut.get_dir(@app['external_dir'])}/#{dir_name}"
          utf.check_file( dir_name, @app['banned_java'] )
          utf.save
          
          output = "#{output} Submitted file: '#{utf.filename}'. "
        end
        ut.calculate_main
        unless @assignment.enable_upload
          ut.sealed = true
          ut.finalized = true 
        end
        
        ut.save
        if ut.finalized
          queue = AutoGradeHelper.schedule( @assignment, @user, ut, @app, flash )
          unless queue.nil?
            ## need to do a different rediect
            @redir_url = url_for :only_path => false, :controller => 'wait', :action => 'grade', :id => queue.id 
          end
        end       
       
        
     
        @path = "#{path}"
        flash[:notice] = "#{output} <br/> <b>Please select 'Manage Submitted Files' to verify your files have been collected</b>"
        render :layout => false, :partial => 'svnlist'
      rescue RuntimeError => re
        unless ut.nil?
          ut.delete_dir( @app['external_dir'] )
          ut.destroy
        end
        flash[:badnotice] = re.message
        render :layout => false
      end 
    end
    
  end


  def assignment_available( assignment, redirect = true )
    unless assignment.open_date <= Time.now
      flash[:badnotice] = "The requisted assignment is not yet available."
      redirect_to :action => 'index' if redirect
      return false
    end
    true
  end
  
  def assignment_open( assignment, redirect = true  ) 
    unless assignment.close_date > Time.now
      flash[:badnotice] = "The requisted assignment is closed, no more files or information may be submitted."
      redirect_to :action => 'index' if redirect
      return false
    end
    true    
  end

  
  def document_in_assignment( document, assignment )
    unless document.assignment_id == assignment.id 
      flash[:badnotice] = "The requested document could not be found."
      redirect_to :action => 'view', :assignment => assignment, :course => @course
      return false
    end
    true
  end


  def set_tab
    @show_course_tabs = true
    @tab = "course_assignments"
    @title = "Course Assignments"
  end

  def set_title
    @title = "#{@course.title} (Course Assignments)"
    @title = "#{@assignment.title} - #{@course.title}" unless @assignment.nil?
  end
  
  def count_todays_turnins( max = 3 )
    now = Time.now
    begin_time = Time.local( now.year, now.mon, now.day, 0, 0, 0 )
    end_time = begin_time + 60*60*24 # plus a day
    @today_count = UserTurnin.count( :conditions => [ "assignment_id = ? and user_id = ? and finalized = ? and updated_at >= ? and updated_at < ?", @assignment.id, @user.id, true, begin_time, end_time ] )
    @remaining_count = max - @today_count 
    @remaining_count = 0 if @remaining_count < 0
  end
  
  private :set_tab, :set_title, :assignment_available, :document_in_assignment, :assignment_open, :count_todays_turnins
  
end
