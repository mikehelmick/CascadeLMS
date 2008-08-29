class Public::DocumentsController < ApplicationController
  
  layout 'public', :except => [:podcast, :podcast_download]
  before_filter :set_tab, :except => [:podcast, :podcast_download]
  
  def index
    return unless load_course( params[:course] )
    return unless course_is_public( @course )
    return unless load_folder( params[:id].to_i )
  
    @page = params[:page].to_i
    @page = 1 if @page.nil? || @page == 0
    @document_pages = Paginator.new self, Document.count(:conditions => ["course_id = ? and published = ? and document_parent = ?", @course.id, true, @folder_id]), 25, @page
    @documents = Document.find(:all, :conditions => ['course_id = ? and published = ? and document_parent = ?', @course.id, true, @folder_id], :order => 'position', :limit => 25, :offset => @document_pages.current.offset)  
   
    set_title
  end
  
  def podcast_download
    if load_course( params[:course] )
      return unless course_is_public( @course )
      
      begin 
        @document = Document.find(params[:id])
        raise 'unpublished' unless @document.published
      rescue
        return
      end
      
      if doc_in_course( @course, @document )
        send_file @document.resolve_file_name(@app['external_dir']), :filename => @document.filename, :type => "#{@document.content_type}", :disposition => 'inline'  
      end
    end
  end
  
  def podcast
    if load_course( params[:course] ) 
      return unless course_is_public( @course )
      if load_folder( params[:id].to_i )
        @documents = Document.find(:all, :conditions => ['course_id = ? and published = ? and document_parent = ?', @course.id, true, @folder_id], :order => 'created_at desc' )  
              
        @fresh_date = @documents[0].created_at rescue @fresh_date = Time.now
              
        headers["Content-Type"] = "application/rss+xml"
      end
    end
  end
  
  def subscribe
    return unless load_course( params[:course] )
    return unless course_is_public( @course )
    return unless load_folder( params[:id].to_i )
    
    if @folder.nil? || !@folder.podcast_folder
      flash[:badnotice] = "The selected folder is not a podcast."
      redirect_to :action => 'index'
    end
  end
  
  def download
    return unless load_course( params[:course] )
    return unless course_is_public( @course )
    
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
      redirect_to :controller => '/public/documents', :course => course
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
    @title = "#{@course.title} (Course Documents - Public Access)"
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
