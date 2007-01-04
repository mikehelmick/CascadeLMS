class DocumentsController < ApplicationController
  
  before_filter :ensure_logged_in
  before_filter :set_tab
  
  def index
    return unless load_course( params[:course] )
    return unless allowed_to_see_course( @course, @user )
    return unless load_folder( params[:id].to_i )
  
    @page = @params[:page].to_i
    @page = 1 if @page.nil? || @page == 0
    @document_pages = Paginator.new self, Document.count(:conditions => ["course_id = ? and document_parent = ?", @course.id, @folder_id]), 50, @page
    @documents = Document.find(:all, :conditions => ['course_id = ? and document_parent = ?', @course.id, @folder_id], :order => 'position', :limit => 50, :offset => @document_pages.current.offset)  
  

    set_title
  end
  
  def download
    return unless load_course( params[:course] )
    return unless allowed_to_see_course( @course, @user )
    
    begin
      @document = Document.find(params[:id])
      raise 'unpublished' unless @document.published
    rescue
      flash[:badnotice] = 'Sorry, the requested document could not be found.'
      redirect_to :action => 'index'
      return
    end
    return unless doc_in_course( @course, @document )
  
    
    begin  
      send_file @document.resolve_file_name(@app['external_dir']), :filename => @document.filename, :type => "#{@document.content_type}", :disposition => 'inline'  
    rescue
      flash[:badnotice] = "Sorry - the requested document has been deleted or is corrupt.  Please notify your instructor of the problem and mention 'document id #{@document.id}'."
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
