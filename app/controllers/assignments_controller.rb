require 'SubversionManager'

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
      return render( :layout => false )
    end
    
    if params[:command].eql?('list_dev') || params[:command].eql?('list_rel')
      
      path = @assignment.development_path_replace(@user.uniqueid)
      path = @assignment.release_path_replace(@user.uniqueid) if params[:command].eql?('list_rel')
      
      svn = SubversionManager.new( @app['subversion_command'] )
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
      svn = SubversionManager.new( @app['subversion_command'] )
      begin
        output = ""
        if params[:command].eql?('release')
          output = svn.create_release( @user.uniqueid, params[:password], @assignment.subversion_server, @assignment.development_path_replace(@user.uniqueid), @assignment.release_path_replace(@user.uniqueid) )  
        end
        
        path = @assignment.release_path_replace(@user.uniqueid)
        
        
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
        
        parent = utf.id
        take_off = ''
        ## create entries in database
        @list_entries.each do |le|
          utf = UserTurninFile.new
          utf.user_turnin = ut
          utf.directory_entry = le.dir?
          utf.directory_parent = parent
          utf.filename = le.name.to_s[take_off.size...le.name.to_s.size]
          ridx = utf.filename.rindex('.')
          unless ridx.nil?
            utf.extension = utf.filename[ridx...utf.filename.size]
          end
          ut.user_turnin_files << utf
          
          if utf.directory_entry
            take_off = "#{take_off}#{utf.filename}/"
            parent = utf.id
          end
          output = "#{output} Submitted file: '#{utf.filename}'. "
        end
        ut.save
     
        @path = "#{path}"
        flash[:notice] = output
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

  def assignment_in_course( assignment, course, redirect = true )
    unless assignment.course_id == course.id 
      flash[:badnotice] = "The requested assignment could not be found."
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
  
  private :set_tab, :set_title, :assignment_in_course, :assignment_available, :document_in_assignment
  
end
