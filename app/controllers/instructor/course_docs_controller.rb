class Instructor::CourseDocsController < Instructor::InstructorBase
 
  before_filter :ensure_logged_in
  before_filter :set_tab
  
  
  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :index }

 
  def index
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_documents' )

    return unless load_folder( params[:id].to_i )
   
    @page = params[:page].to_i
    @page = 1 if @page.nil? || @page == 0
    @document_pages = Paginator.new self, Document.count(:conditions => ["course_id = ? and document_parent = ?", @course.id, @folder_id]), 50, @page
    @documents = Document.find(:all, :conditions => ['course_id = ? and document_parent = ?', @course.id, @folder_id], :order => 'position', :limit => 50, :offset => @document_pages.current.offset)  
     
    set_title
  end
  
  def new
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_documents' )
    return unless course_open( @course, :action => 'index' )
    
    return unless load_folder( params[:id].to_i )
    
    @title = "Upload new document: #{@course.title}"
    @document = Document.new
  end

  def create
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_documents' )
    return unless course_open( @course, :action => 'index' )
    return unless load_folder( params[:id].to_i )
    
    # Load the new doc, so they can stay
    @document = Document.new(params[:document])

    # Check that a file was uploaded
    file_field = params[:file]
    if file_field.nil? || file_field.eql?('') || file_field.class.to_s.eql?('String')
      @title = "Upload new document: #{@course.title}"
      flash[:badnotice] = "You must select a file for upload."
      render :action => 'new'
      return
    end
    
    @document.course = @course
    @document.set_file_props( params[:file] ) unless params[:file].class.to_s.eql?('String')
    @document.document_parent = @folder_id
    @document.folder = false
    @document.podcast_folder = false
    
    if @document.save
      @document.create_file( params[:file], @app['external_dir'] )
       
      flash[:notice] = 'File was successfully uploaded.'
      redirect_to :action => 'index', :id => @folder_id
    else
      render :action => 'new'
    end
  end
  
  def new_folder
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_documents' )
    return unless course_open( @course, :action => 'index' )
    
    return unless load_folder( params[:id].to_i )
    
    if !@folder.nil? && 
      if @folder.podcast_folder
        flash[:badnotice] = "You can not create a subfolder in a podcast folder."
        redirect_to :action => 'index', :id => @folder_id
      end
    end
    
    @document = Document.new
  end
  
  def create_folder
    
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_documents' )
    return unless course_open( @course, :action => 'index' )
    return unless load_folder( params[:id].to_i )
    
    @document = Document.new(params[:document])
    @document.course = @course
    @document.filename = @document.title
    @document.folder = true
    @document.document_parent = @folder_id
    @document.content_type = 'folder'
    
    if @document.save
      flash[:notice] = 'Folder was created successfully.'
      redirect_to :action => 'index', :id => @document.id
    else
      render :action => 'new_folder'
    end
  end

  def toggle_published
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_documents' )
    return unless course_open( @course, :action => 'index' )
    
    @document = Document.find(params[:id])
    return unless doc_in_course( @course, @document )
    
    @document.toggle_published
    @document.save
    render(:partial => 'published', :locals => {:document => @document}, :layout => false)
  end

  def edit
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_documents' )
    return unless course_open( @course, :action => 'index' )
    
    @document = Document.find(params[:id])
    return unless doc_in_course( @course, @document )

    load_folder( @document.document_parent )
  end

  def update
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_documents' )
    return unless course_open( @course, :action => 'index' )
    
    @document = Document.find(params[:id])
    return unless doc_in_course( @course, @document )
    
    if @document.update_attributes(params[:document])
      
      unless params[:file].nil? || params[:file].class.to_s.eql?('String')
        @document.delete_file( @app['external_dir'] )
        @document.set_file_props( params[:file] )
        @document.create_file( params[:file], @app['external_dir'] )
      end
      
      flash[:notice] = 'Document was successfully updated.'
      redirect_to :action => 'index', :id => @document.document_parent
    else
      render :action => 'edit'
    end
  end
  
  def edit_folder
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_documents' )
    return unless course_open( @course, :action => 'index' )
    
    @document = Document.find(params[:id])
    return unless doc_in_course( @course, @document )
    load_folder( @document.document_parent )
  end
  
  def update_folder
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_documents' )
    return unless course_open( @course, :action => 'index' )
    
    @document = Document.find(params[:id])
    return unless doc_in_course( @course, @document )

    if @document.update_attributes(params[:document])
        flash[:notice] = 'Folder name was successfully updated.'
        redirect_to :action => 'index', :id => @document.document_parent
      else
        render :action => 'edit_folder'
      end
  end
  
  def reorder
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_documents' )

    return unless load_folder( params[:id].to_i )
   
    @documents = Document.find(:all, :conditions => ['course_id = ? and document_parent = ?', @course.id, @folder_id], :order => 'position')  
     
    @title = "Reorder documents : #{@course.title}"
  end

  def sort
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_documents', 'ta_grade_individual', 'ta_view_student_files' )
    
    return unless load_folder( params[:id].to_i )
    
    @documents = Document.find(:all, :conditions => ['course_id = ? and document_parent = ?', @course.id, @folder_id], :order => 'position')

    # reorder...
    Document.transaction do
      @documents.each do |document|
        document.position = params['document-order'].index( document.id.to_s ) + 1
        document.save
      end
    end
    
    render :nothing => true
  end

  def accesses
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_documents' )
    
    @document = Document.find(params[:id])
    return unless doc_in_course( @course, @document )

    @access_map = DocumentAccess.user_map_for_document(@document)
    @students = @course.students
    @title = "Document access report for '#{@document.title}'"
  end
  
  def download
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_documents' )
    
    @document = Document.find(params[:id])
    return unless doc_in_course( @course, @document )
    
    send_file @document.resolve_file_name(@app['external_dir']), :filename => @document.filename, :disposition => 'inline'
  end

  def destroy
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_documents' )
    return unless course_open( @course, :action => 'index' )
    
    @document = Document.find(params[:id])
    
    @folder_id = @document.document_parent
    
    @document.delete_file( @app['external_dir'] )
    @document.destroy
    
    flash[:notice] = "Document #{@document.title} has been deleted."
    redirect_to :action => 'index', :id => @folder_id
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
  
  private :set_tab, :set_title, :doc_in_course, :load_folder
  
end
