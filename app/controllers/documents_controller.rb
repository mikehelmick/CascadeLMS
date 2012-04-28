class DocumentsController < ApplicationController
  
  before_filter :ensure_logged_in, :except => [:podcast, :podcast_download]
  before_filter :set_tab, :except => [:podcast, :podcast_download]
  
  layout 'noright', :except => [:podcast, :podcast_download]
  
  def index
    return unless load_course( params[:course] )
    return unless allowed_to_see_course( @course, @user )
    return unless load_folder( params[:id].to_i )
    
    @instructor = @user.instructor_in_course?(@course.id)
    
    time = Time.now
    respond_to do |format|
      format.html {
        @page = params[:page].to_i
        @page = 1 if @page.nil? || @page == 0
        @document_pages = Paginator.new self, Document.count(:conditions => ["course_id = ? and published = ? and document_parent = ? and created_at < ?", @course.id, true, @folder_id, time]), 50, @page
        @documents = Document.find(:all, :conditions => ['course_id = ? and published = ? and document_parent = ? and created_at < ?', @course.id, true, @folder_id, time], :order => 'position', :limit => 50, :offset => @document_pages.current.offset)  

        set_title        
      }
      format.xml { 
        @documents = Document.find(:all, :conditions => ['course_id = ? and published = ? and document_parent = ? and created_at < ?', @course.id, true, @folder_id, time], :order => 'position') 
        render :layout => false
      }
    end
  end
  
  def podcast_download
    return unless load_course( params[:course] )
    @user = rss_authorize( "CSCourseware podcast for course '#{@course.title}'.")
    
    unless @user.nil?
      if @course
        if allowed_to_see_course( @course, @user )
    
          begin 
            @document = Document.find(params[:id])
            raise 'unpublished' unless @document.visible_to_students()
          rescue
            return
          end
          if doc_in_course( @course, @document )
            @document.log_access(@user)
            send_file @document.resolve_file_name(@app['external_dir']), :filename => @document.filename, :type => "#{@document.content_type}", :disposition => 'inline'  
          end
        end
      end
    end
  end
  
  def podcast
    return unless load_course( params[:course] )
    @user = rss_authorize( "CSCourseware podcast for course '#{@course.title}'.")
    return if @user.nil?
    
    request.env["HTTP_ACCEPT"] = "*/*"
    unless @user.nil?
      session[:user] = @user
      
      unless @course.nil?
          if allowed_to_see_course( @course, @user )       
            if load_folder( params[:id].to_i )
              if @folder.nil?
                redirect_to :controller => "/home", :action => nil, :course => nil
              end
              
              params[:format] = 'xml'
              time = Time.now
              respond_to do |format| 
                format.xml {
                  @documents = Document.find(:all, :conditions => ['course_id = ? and published = ? and document_parent = ? and created_at < ?', @course.id, true, @folder_id, time], :order => 'created_at desc' )               
                  @fresh_date = @documents[0].created_at rescue @fresh_date = Time.now
                }
              end
            end
            ## not loaded folder
          end
          #render_text( 'You are not authorized to view this RSS feed.', 401 ) 
        end
        #render_text( 'You are not authorized to view this RSS feed.', 401 ) 
    end
    
  end
  
  def download
    return unless load_course( params[:course] )
    return unless allowed_to_see_course( @course, @user )
    
    begin
      @document = Document.find(params[:id])
      raise 'unpublished' unless @document.visible_to_students()
    rescue
      flash[:badnotice] = 'Sorry, the requested document could not be found.'
      redirect_to :action => 'index'
      return
    end
    return unless doc_in_course( @course, @document )
  
    
    begin
      @document.log_access(@user)
      send_file @document.resolve_file_name(@app['external_dir']), :filename => @document.filename, :type => "#{@document.content_type}", :disposition => 'inline'  
    rescue
      flash[:badnotice] = "Sorry - the requested document has been deleted or is corrupt.  Please notify your instructor of the problem and mention 'document id #{@document.id}'."
      redirect_to :action => 'index'
    end
  end
  
  def subscribe
    return unless load_course( params[:course] )
    return unless allowed_to_see_course( @course, @user )
    return unless load_folder( params[:id].to_i )
    
    if @folder.nil? || !@folder.podcast_folder
      flash[:badnotice] = "The selected folder is not a podcast."
      redirect_to :action => 'index'
    end
    
  end
  
  def doc_in_course( course, doc )
    unless course.id == doc.course.id
      redirect_to :controller => '/documents', :course => course
      flash[:notice] = "Requested document could not be found."
      return false
    end
    true
  end
  
  def set_tab
    @show_course_tabs = true
    @tab = "course_documents"
    @title = "Course Documents"
  end
  
  def set_title
    @title = "#{@course.title} (Course Documents)"
  end
  
  def load_folder( folder_id )
    @folder_id = folder_id
    @folder_id = 0 if @folder_id.nil?
    
    @folder = nil
    if @folder_id > 0 
      @folder = Document.find(@folder_id) rescue @folder=nil
      
      if @folder.nil? || @folder.course_id != @course.id
        flash[:badnotice] = "The requested folder could not be found in this course or does not exist."
        redirect_to :action => 'index', :id => nil
        return false
      end
      
    end
    return true
  end
  
  private :set_tab, :set_title, :load_folder
  
end
