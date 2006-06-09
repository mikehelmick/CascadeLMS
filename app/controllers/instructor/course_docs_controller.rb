class Instructor::CourseDocsController < Instructor::InstructorBase
 
  before_filter :ensure_logged_in
  before_filter :set_tab
 
  def index
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_documents' )
   
    @page = @params[:page].to_i
    @page = 1 if @page.nil? || @page == 0
    @document_pages = Paginator.new self, Document.count(:conditions => ["course_id = ?", @course.id]), 50, @page
    @documents = Document.find(:all, :conditions => ['course_id = ?', @course.id], :order => 'position', :limit => 50, :offset => @document_pages.current.offset)  
     
    set_title
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :index }

  def new
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_documents' )
    
    
    @document = Document.new
  end

  def create
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_documents' )
    
    @document = Document.new(params[:document])
    @document.course = @course
    @document.set_file_props( params[:file] ) unless params[:file].class.to_s.eql?('String')
    
    if @document.save
      @document.create_file( params[:file], @app['external_dir'] )
        
      
      flash[:notice] = 'Document was successfully created.'
      redirect_to :action => 'index'
    else
      render :action => 'new'
    end
  end

  def edit
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_documents' )
    
    @document = Document.find(params[:id])
    return unless doc_in_course( @course, @document )
  end

  def update
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_documents' )
    
    @document = Document.find(params[:id])
    return unless doc_in_course( @course, @document )
    
    if @document.update_attributes(params[:document])
      
      unless params[:file].nil? || params[:file].class.to_s.eql?('String')
        @document.delete_file( @app['external_dir'] )
        @document.set_file_props( params[:file] )
        @document.create_file( params[:file], @app['external_dir'] )
      end
      
      flash[:notice] = 'Document was successfully updated.'
      redirect_to :action => 'index', :id => @document
    else
      render :action => 'edit'
    end
  end
  
  def move_up
      return unless load_course( params[:course] )
      return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_documents' )

      @document = Document.find(params[:id])
      return unless doc_in_course( @course, @document )
 
      (@course.documents.to_a.find {|s| s.id == @document.id}).move_higher
      set_highlight "document_#{@document.id}"
	    redirect_to :action => 'index'
  end
  
  def move_down
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_documents' )

    @document = Document.find(params[:id])
    return unless doc_in_course( @course, @document )

    (@course.documents.to_a.find {|s| s.id == @document.id}).move_lower
    set_highlight "document_#{@document.id}"
    redirect_to :action => 'index'
  end
  
  def download
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_documents' )
    
    @document = Document.find(params[:id])
    return unless doc_in_course( @course, @document )
    
    send_file @document.resolve_file_name(@app['external_dir']), :filename => @document.filename, :disposition => 'inline'
  end

  def destroy
    @document = Document.find(params[:id])
    @document.delete_file( @app['external_dir'] )
    @document.destroy
    
    flash[:notice] = "Document #{@document.title} has been deleted."
    redirect_to :action => 'index'
  end
  
  def set_tab
    @show_course_tabs = true
    @tab = "course_instructor"
  end
  
  def set_title
    @title = "Course Documents - #{@course.title}"
  end
  
  def doc_in_course( course, doc )
    unless course.id == doc.course.id
      redirect_to :controller => '/instructor/index', :course => course
      flash[:notice] = "Requested document could not be found."
      return false
    end
    true
  end
  
  private :set_tab, :set_title, :doc_in_course
  
end
