class Instructor::ImportController < Instructor::InstructorBase

  before_filter :ensure_logged_in
  before_filter :set_tab
    
  def index
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_on_assistant( @course, @user )
  
    @courses = @user.courses
    @courses.sort! do |a,b|  
      rtn = b.term.term <=> a.term.term
      rtn = b.title <=> a.title if rtn == 0
      rtn
    end
    
    @blog_count = Hash.new
    @assignment_count = Hash.new
    @document_count = Hash.new
    @rubric_count = Hash.new
    
    @courses.each do |course|
      @blog_count[course.id] = course.posts.size
      @document_count[course.id] = course.documents.size
      @assignment_count[course.id] = course.assignments.size
      @rubric_count[course.id] = course.rubrics.size
    end
    
    @shares = @user.course_shares
    
    @shares.each do |share|
      @blog_count[share.course.id] = share.course.posts.size
      @document_count[share.course.id] = share.course.documents.size
      @assignment_count[share.course.id] = share.course.assignments.size
      @rubric_count[share.course.id] = share.course.rubrics.size
    end
  
    set_title
  end
  
  def start
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_on_assistant( @course, @user )
    
    @import_from = Course.find(params[:id].to_i)
    @course_share = @user.course_share(@import_from.id)
    
    if !@user.instructor_in_course?(@course.id) && @course_share.nil?
      flash[:bad_notice] = "You do not have permission to import contect from the selected course."
      redirect_to :action => 'index', :course => @course, :id => nil
    end

    @title = "Import content from #{@import_from.title} into #{@course.title}"
  end
  
  def import_data
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_on_assistant( @course, @user )
    
    @import_from = Course.find(params[:id].to_i)
    @course_share = @user.course_share(@import_from.id)
    
    if @import_from.nil? || (!@user.instructor_in_course?(@import_from.id) && @course_share.nil?)
      flash[:badnotice] = "You do not have permission to import contect from the selected course."
      redirect_to :controller => '/instructor/import', :action => nil, :course => @course, :id => nil
      return
    end
    
    ## The @coure_share object is going to be used for all permission enforcement, so create a new one if instructor.
    if @user.instructor_in_course?(@import_from.id)
      @course_share = CourseShare.full_share
    end
    
    ## For reporting on the results page
    @imported_posts = Array.new
    @imported_documents = Array.new
    @imported_assignments = Array.new
    @imported_rubrics = Array.new
    
    @errorMessages = Array.new
    
    Course.transaction do   
      params.keys.each do |key|
        
      ## BLOG IMPORTS
      if key.index('post_') ==  0
        postId = key.split('_')[1].to_i rescue postId = 0
        if (postId == 0) 
          @errorMessages << "Invalid post specified, cannot import."
        else
          cloneFromPost = Post.find(postId)

          if !@course_share.blogs || cloneFromPost.course_id != @import_from.id
            @errorMessages << "You are not authorized to import the blog post '#{cloneFromPost.title}' from the course '#{@import_from.title}'."
          else
            new_post = cloneFromPost.clone_to_course(@course.id, @user.id)
            new_post.save
            @imported_posts << new_post
          end
        end
        
      ## DOCUMENT IMPORTS
      elsif key.index('document_') == 0
        docId = key.split('_')[1].to_i rescue docId = 0
        if (docId == 0) 
          @errorMessages << "Invalid post specified, cannot import."
        else
          cloneFromDoc = Document.find(docId)
          
          if !@course_share.documents || cloneFromDoc.course_id != @import_from.id
            @errorMessages << "You are not authorized to import the document '#{cloneFromDoc.title}' from the course '#{@import_from.title}'."
          else
            dir_created = false
            
            copyFromParentFolders = cloneFromDoc.get_parent_folders
            
            # These parent directories either need to be created
            parentFolder = nil
            copyFromParentFolders.each do |folder|
              prevParentId = if parentFolder.nil?
                               0
                             else
                               parentFolder.id
                             end    
              # See if there is an existing folder with the same name
              localFolder = Document.find(:first, :conditions => ["course_id = ? and document_parent = ? and folder = ? and title = ?", @course.id, prevParentId, true, folder.title])
              
              if localFolder.nil?
                # Create a folder 
                localFolder = Document.new
                localFolder.course = @course
                localFolder.title = folder.title
                localFolder.filename = folder.filename
                localFolder.content_type = 'folder'
                localFolder.published = folder.published
                localFolder.folder = true
                localFolder.document_parent = prevParentId
                localFolder.save
              end
              parentFolder = localFolder
            end
            
            # parentFolder is now the appropriate parent folder, or nil (zero)
            new_doc = cloneFromDoc.clone_to_course(@course.id, @user.id)
            new_doc.document_parent = parentFolder.id rescue new_doc.document_parent = 0
            new_doc.published = false
            new_doc.save
            new_doc.ensure_directory_exists(@app['external_dir'])
            
            # copy the file
            from_file_name = cloneFromDoc.resolve_file_name(@app['external_dir'])
            to_file_name = new_doc.resolve_file_name(@app['external_dir'])
            ## shell out to copy file
            `cp #{from_file_name} #{to_file_name}`
            
            @imported_documents << new_doc
          end
        end  
      
      ## ASSIGNMENT IMPORTS  
      elsif key.index('assignment_') == 0
        assignmentId = key.split('_')[1].to_i rescue assignmentId = 0
        if (assignmentId == 0) 
          @errorMessages << "Invalid assignment specified, cannot import."
        else
          cloneFromAssignment = Assignment.find(assignmentId)

          if !@course_share.assignments || cloneFromAssignment.course_id != @import_from.id
            @errorMessages << "You are not authorized to import the assignment '#{cloneFromAssignment.title}' from the course '#{@import_from.title}'."
          else
            new_assignment = cloneFromAssignment.clone_to_course(@course.id, @user.id, 0, @app['external_dir'])
            new_assignment.visible = false
            new_assignment.save
            @imported_assignments << new_assignment
          end
        end
      
      ## RUBRIC IMPORTS
      elsif key.index('rubric_') == 0
        rubricId = key.split('_')[1].to_i rescue rubricId = 0
        if (rubricId == 0) 
          @errorMessages << "Invalid rubric specified, cannot import."
        else
          cloneFromRubric = Rubric.find(rubricId)

          if !@course_share.rubrics || cloneFromRubric.course_id != @import_from.id
            @errorMessages << "You are not authorized to import the rubric '#{rubric.primary_trait}' from the course '#{@import_from.title}'."
          else
            new_rubric = cloneFromRubric.copy_to_course(@course)
            new_rubric.save
            @imported_rubrics << new_rubric
          end
        end
      end

      ## end of loop          
      end  
      ## end of transaction
    end
    
    flash[:badnotice] = @errorMessages.join(', ') if @errorMessages.size > 0
    
    @title = "Import Results - #{@course.title}"
  end
  
  private
  
  def set_tab
    @show_course_tabs = true
    @tab = "course_instructor"
  end
  
  def set_title
    @title = "Import Content - #{@course.title}"
  end

end
