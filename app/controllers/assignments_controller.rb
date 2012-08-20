require 'SubversionManager'
require 'auto_grade_helper'

class AssignmentsController < ApplicationController
  
  before_filter :ensure_logged_in
  before_filter :set_tab, :except => [ :svn_command ]  

  def index
    return unless load_course( params[:course] )
    return unless allowed_to_see_course( @course, @user )

    set_title

    @instructor = @user.instructor_in_course?(@course.id)
    
    @assignments = @course.assignments_for_user( @user.id )
    
    @current_assignments = Array.new
    @upcoming_assignments = Array.new
    @complete_assignments = Array.new

    @assignments.each do |a|
      if a.current?
        @current_assignments << a
      elsif a.upcoming?
        @upcoming_assignments << a
      else
        @complete_assignments << a
      end
    end
    
    RubricLevel.for_course(@course)
    @public = false
    
    respond_to do |format|
      format.html
      format.xml { render :layout => false }
    end
  end
  
  def view
    return unless load_course( params[:course] )
    return unless allowed_to_see_course( @course, @user )
    
    @instructor = @user.instructor_in_course?(@course.id)
    
    @assignment = Assignment.find(params[:id]) rescue @assignment = Assignment.new

    if ! @assignment.quiz.nil?
      flash[:notice] = "The selected assignment is a quiz, there are no details to view."
      redirect_to :action => 'index', :course => @course, :assignment => nil, :id => nil
      return
    end

    return unless assignment_in_course( @assignment, @course )
    if !@instructor
      return unless assignment_available( @assignment )
      return unless assignment_available_for_students_team( @course, @assignment, @user.id )
    end
    return unless load_team( @course, @assignment, @user )
    
      
    if @assignment.use_subversion && @assignment.auto_grade
      count_todays_turnins( @app["turnin_limit"].to_i )
    end
    
    if @assignment.enable_journal
      @journals = @user.assignment_journals( @assignment )
      
      unless @assignment.journal_field.nil?
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
    end
    
    @numbers = load_outcome_numbers(@course) if @assignment.rubrics.size > 0 
    
    @extension = @assignment.extension_for_user( @user )
    
    @now = Time.now
    set_title(@assignment)
    
    respond_to do |format|
      format.html
      format.xml { render :layout => false }
    end    
  end

  def download
    return unless load_course( params[:course] )
    return unless allowed_to_see_course( @course, @user )
    
    @assignment = Assignment.find(params[:id]) rescue @assignment = Assignment.new
    return unless assignment_in_course( @assignment, @course )
    return unless assignment_available( @assignment )
    return unless assignment_available_for_students_team( @course, @assignment, @user.id )
    
    @document = AssignmentDocument.find(params[:document]) rescue @document = AssignmentDocument.new
    return unless document_in_assignment( @document, @assignment )
    
    if @document.keep_hidden
      flash[:badnotice] = 'The requested document cannot be downloaded at this time.'
      redirect_to :action => 'view', :id => @assignment, :course => @course
      return
    end   
       
    begin  
      send_file @document.resolve_file_name(@app['external_dir']), :filename => @document.filename, :type => "#{@document.content_type}", :disposition => 'inline'  
    rescue
      flash[:badnotice] = "Sorry - the requested document has been deleted or is corrupt.  Please notify your instructor of the problem and mention 'assignment document id #{@document.id}'."
      redirect_to :action => 'view', :id => @assignment, :course => @course
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
    
    return render( :layout => false ) unless load_team( @course, @assignment, @user )
    
    if params[:password].nil? || params[:password].size == 0 
      flash[:badnotice] = "You must enter your password."
      sleep( 0.2 )
      return render( :layout => false )
    end
    
    if params[:command].eql?('list_dev') || params[:command].eql?('list_rel')
      path = @assignment.development_path_replace(@user.uniqueid, @team )
      path = @assignment.release_path_replace(@user.uniqueid, @team ) if params[:command].eql?('list_rel')
      
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
        flash[:notice] = svn.create_directory( @user.uniqueid, params[:password], @assignment.subversion_server, @assignment.development_path_replace(@user.uniqueid,@team) )
        @list_entries = svn.list( @user.uniqueid, params[:password], @assignment.subversion_server, @assignment.development_path_replace(@user.uniqueid,@team) )  
        @path = "#{@assignment.development_path_replace(@user.uniqueid,@team)}"
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
      ut = nil
      begin
        output = ""
        if params[:command].eql?('release')
          output = svn.create_release( @user.uniqueid, params[:password], @assignment.subversion_server, @assignment.development_path_replace(@user.uniqueid,@team), @assignment.release_path_replace(@user.uniqueid,@team) )  
        end
        
        path = @assignment.release_path_replace(@user.uniqueid,@team)
        
        UserTurnin.transaction do
          
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
           ut.position = 1
           ut.position = @current_turnin.position + 1 unless @current_turnin.nil?
           ut.project_team = @team unless @team.nil?
           ut.save

           ut.make_dir( @app['external_dir'], @team )

           fs_dir = ut.get_dir( @app['external_dir'] )
           fs_dir = ut.get_team_dir( @app['external_dir'], @team ) unless @team.nil?

           @list_entries = svn.get_release_files( @user.uniqueid, params[:password], @assignment.subversion_server, path, fs_dir )
           @list_entries.sort! { |a,b| a.name.to_s.downcase <=> b.name.to_s.downcase }
          
           ## Map to reverse lookup directory utf entries
           svn_dir_map = Hash.new
          
           # create root entry
           utf = UserTurninFile.new
           utf.user_turnin = ut
           utf.directory_entry = true
           utf.directory_parent = 0
           utf.filename = '/'
           utf.user = @user
           ut.user_turnin_files << utf
           ut.save
           svn_dir_map['/'] = utf

           root_dir_entry = utf.id

           ### create the directory entries
           @list_entries.each do |le|
             if ( le.dir? )
               #puts "PROCESSING #{le.name} - #{ut.user_turnin_files.class}"
               
               utf = UserTurninFile.new
               utf.user = @user
               utf.user_turnin = ut
               utf.directory_entry = true # it is a dir at this point
               
               if le.name.to_s.index('/').nil?
                 # has no slash  - so it is a child of root
                 utf.filename = le.name.to_s
                 utf.directory_parent = root_dir_entry
                 ut.user_turnin_files.insert( utf )
                 svn_dir_map[le.name.to_s] = utf
               else 
                 last_slash_idx = le.name.to_s.rindex('/')
                 prefix = le.name.to_s[0...last_slash_idx]
                 
                 after = svn_dir_map[prefix]
                 #puts "#{le.name.to_s} has prefix '#{prefix}' and goes after '#{after.filename}'"
                 
                 filename = le.name.to_s[last_slash_idx+1..le.name.to_s.length]
                 
                 utf.filename = filename
                 utf.directory_parent = after.id
                 
                 ut.user_turnin_files.insert( utf )
                 
                 svn_dir_map[le.name.to_s] = utf
               end
               utf.save
             end
           end
           ut.save
           
           @list_entries.each do |le|
             unless ( le.dir? )
               #puts "PROCESSING #{le.name} - #{ut.user_turnin_files.class}"
               
               utf = UserTurninFile.new
               utf.user = @user
               utf.user_turnin = ut
               utf.directory_entry = false 
               
               if le.name.to_s.index('/').nil?
                  # has no slash  - so it is a child of root
                  utf.filename = le.name.to_s
                  utf.directory_parent = root_dir_entry
               else
                  last_slash_idx = le.name.to_s.rindex('/')
                  prefix = le.name.to_s[0...last_slash_idx]

                  after = svn_dir_map[prefix]
                  #puts "#{le.name.to_s} has prefix '#{prefix}' and goes after '#{after.filename}'"

                  filename = le.name.to_s[last_slash_idx+1..le.name.to_s.length]

                  utf.filename = filename
                  utf.directory_parent = after.id.to_i
                  #puts "BEFORE SAVE: goes after #{utf.directory_parent} #{after.filename} #{after.id}"

               end
               
               # set extension   
               ridx = utf.filename.to_s.rindex('.') 
               unless ridx.nil?
                 utf.extension = utf.filename[(ridx+1)...utf.filename.size]
               end
               
               ut.user_turnin_files.insert( utf )
               utf.save
               ut.save
               
               
               #puts "TRYING TO PLACE '#{utf.filename}' position=#{utf.position}"
               
               
               ### while the one above is not the parent, or does not have the same parent
               one_above = utf.higher_item
               #puts "ONE ABOVE IF '#{one_above.filename}' position=#{one_above.position}"
               while( (utf.directory_parent.to_i != one_above.directory_parent.to_i && utf.directory_parent.to_i != one_above.id ) ||
                      (utf.directory_parent.to_i == one_above.directory_parent.to_i && one_above.directory_entry ) )
                  utf.move_higher
                  one_above = utf.higher_item
               end
               
               
               ### Check external file
               mover = UserTurninFile.get_parent( ut.user_turnin_files, utf )
               dir_name = ''
               while( mover.directory_parent > 0 )
                 dir_name = UserTurninFile.prepend_dir( mover.filename, dir_name )
                 mover = UserTurninFile.get_parent( ut.user_turnin_files, mover )
               end
               ## put the appropriate team/individual path in front of the relative file system
               if @team.nil?
                 dir_name = "#{ut.get_dir(@app['external_dir'])}/#{dir_name}"
               else
                 dir_name = "#{ut.get_team_dir(@app['external_dir'], @team)}/#{dir_name}"
               end
               utf.check_file( dir_name, @app['banned_java'] )
               utf.save
               ut.save
               
             end
           end
           
           
           ut.calculate_main
           unless @assignment.enable_upload
             ut.sealed = true
             ut.finalized = true 
           end

           ut.save
           @redir_url = nil
           if ut.finalized
             begin
               queue = AutoGradeHelper.schedule( @assignment, @user, ut, @app, flash )
               unless queue.nil?
                 ## need to do a different rediect
                 @redir_url = url_for :only_path => false, :controller => 'wait', :action => 'grade', :id => queue.id 
               end
             rescue
             end
           end
        
        end ## Transaction end
       
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

  private
  
  def load_team( course, assignment, user )
    @team = nil
    if assignment.team_project
      @team = course.team_for_user( user.id )
      unless @team.nil?
        return true
      end
      
      flash[:badnotice] = "This is a group project and requires assignment to a team in order to turn in files.  Please contact your instructor to be assigned to a team."
      redirect_to :controller => '/assignments', :action => 'view', :course => course.id, :id => assignment.id
      return false
    end
    return true #no team required
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

  def set_title(assignment = nil)
    @title = "#{@course.title} (Course Assignments)"
    @title = "#{@assignment.title} - #{@course.title}" unless @assignment.nil?
    @breadcrumb = Breadcrumb.for_course(@course)
    if assignment.nil?
      @breadcrumb.text = 'Assignments'
      @breadcrumb.link = url_for(:action => 'index', :id => nil)
    else
      @breadcrumb.assignment = assignment
    end
  end
  
  def count_todays_turnins( max = 3 )
    now = Time.now
    begin_time = Time.local( now.year, now.mon, now.day, 0, 0, 0 )
    end_time = begin_time + 60*60*24 # plus a day
    if @team.nil?
      @today_count = UserTurnin.count( :conditions => [ "assignment_id = ? and user_id = ? and finalized = ? and updated_at >= ? and updated_at < ?", @assignment.id, @user.id, true, begin_time, end_time ] )
    else
      @today_count = UserTurnin.count( :conditions => [ "assignment_id = ? and project_team_id = ? and finalized = ? and updated_at >= ? and updated_at < ?", @assignment.id, @team.id, true, begin_time, end_time ] )
    end
    @remaining_count = max - @today_count 
    @remaining_count = 0 if @remaining_count < 0
  end
  
end
