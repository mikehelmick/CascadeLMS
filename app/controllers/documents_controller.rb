class DocumentsController < ApplicationController
  
  before_filter :ensure_logged_in
  before_filter :set_tab
  
  def index
    return unless load_course( params[:course] )
    return unless allowed_to_see_course( @course, @user )
  
    @page = @params[:page].to_i
    @page = 1 if @page.nil? || @page == 0
    @document_pages = Paginator.new self, Document.count(:conditions => ["course_id = ?", @course.id]), 30, @page
    @documents = Document.find(:all, :conditions => ['course_id = ?', @course.id], :order => 'created_at asc', :limit => 30, :offset => @document_pages.current.offset)  
  
    set_title
  end
  
  def download
    return unless load_course( params[:course] )
    return unless allowed_to_see_course( @course, @user )
    
    begin
      @document = Document.find(params[:id])
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
      redirect_to :controller => '/instructor/index', :course => course
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
  
  private :set_tab, :set_title
  
end
