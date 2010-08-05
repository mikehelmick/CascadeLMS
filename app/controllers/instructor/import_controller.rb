class Instructor::ImportController < Instructor::InstructorBase

  before_filter :ensure_logged_in
  before_filter :set_tab
  
  def index
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_on_assistant( @course, @user )
  
    @courses = @user.courses
    @courses.sort! do |a,b|  
      rtn = a.term.semester <=> b.term.semester
      rtn = a.title <=> b.title if rtn == 0
      rtn
    end
    
    @blog_count = Hash.new
    @first_blog = Hash.new
    @assignment_count = Hash.new
    @first_assignment = Hash.new
    @document_count = Hash.new
    @first_document = Hash.new
    
    
    @courses.each do |course|
      @blog_count[course.id] = course.posts.size
      @first_blog[course.id] = course.posts[-1] unless course.posts.size == 0
      
      @document_count[course.id] = course.documents.size
      @first_document[course.id] = course.documents[0] unless course.documents.size == 0
      course.documents.each do |doc|
        @first_document[course.id] = doc if doc.created_at < @first_document[course.id].created_at
      end

      @assignment_count[course.id] = course.assignments.size
      @first_assignment[course.id] = course.assignments[0] unless course.assignments.size == 0
      course.assignments.each do |asgn|
        @first_assignment[course.id] = asgn if asgn.open_date < @first_assignment[course.id].open_date
      end
      
    end
    
  
    set_title
  end
  
  def import_data
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_on_assistant( @course, @user )
    
    @import_from = Course.find(params[:id].to_i)
    
    if @import_from.nil? || !@user.instructor_in_course?(@import_from.id)
      flash[:badnotice] = "Invalid course to import from, please select another."
      redirect_to :controller => '/instructor/import', :action => nil, :course => @course, :id => nil
      return
    end
    
    @start_date = Date.civil(params[:import][:"relative_to(1i)"].to_i,params[:import][:"relative_to(2i)"].to_i,params[:import][:"relative_to(3i)"].to_i)
    clone_time = Time.now
    
    @imported_posts = Array.new
    @imported_documents = Array.new
    @imported_assignments = Array.new
    
    Course.transaction do
      # find overall min date of selected import items for data adjustement
      @min_date = nil
      if params[:import_blog]
        blog_min_date = Post.find(:first, :conditions => ["course_id = ?", @import_from.id], :order => 'created_at ASC').created_at
        @min_date = blog_min_date if @min_date.nil? || blog_min_date < @min_date
      end
      if params[:import_documents]
        doc_min_date = Document.find(:first, :conditions => ["course_id = ?", @import_from.id], :order => 'created_at ASC').created_at
        @min_date = doc_min_date if @min_date.nil? || doc_min_date < @min_date
      end
      if params[:import_assignments]
        assignment_min_date = Assignment.find(:first, :conditions => ["course_id = ?", @import_from.id], :order => 'open_date ASC').open_date
        @min_date = assignment_min_date if @min_date.nil? || assignment_min_date < @min_date
      end
      distance = @start_date.to_time - @min_date.to_time
      
      ## BLOG IMPORTS
      if params[:import_blog]
        @import_from.posts.each do |post|
          new_post = post.clone_to_course( @course.id, @user.id, distance )
          if new_post.created_at > clone_time
            new_post.published = false
          end
          new_post.save
          @course.posts << new_post
          @imported_posts << new_post
        end
      end
      
      ## Document imports
      if params[:import_documents]
        dir_created = false
        parent_map = Hash.new
        parent_map[0] = 0
        import_stack = Document.find(:all, :conditions => ["course_id = ? and document_parent = ?", @import_from.id, 0], :order => "position DESC")
        # Process these as a stack
        while import_stack.size > 0
          copy_from = import_stack.pop
          new_doc = copy_from.clone_to_course( @course.id, @user.id, distance)
          new_doc.document_parent = parent_map[copy_from.document_parent]
          new_doc.save
          parent_map[copy_from.id] = new_doc.id
          
          # create dir
          new_doc.ensure_directory_exists(@app['external_dir']) unless dir_created
          dir_created = true
          
          ## If copy_from is a folder, load contents into stack
          if copy_from.folder
            contents = Document.find(:all, :conditions => ["course_id = ? and document_parent = ?", @import_from.id, copy_from.id], :order => "position DESC")
            contents.each { |i| import_stack.push(i) }
          else
            ## Need to actually copy the file
            from_file_name = copy_from.resolve_file_name(@app['external_dir'])
            to_file_name = new_doc.resolve_file_name(@app['external_dir'])
            ## shell out to copy file
            `cp #{from_file_name} #{to_file_name}`
          end
          
          @imported_documents << new_doc
        end  
      end
    
      ## Assignment imports
      if params[:import_assignments]  
        @import_from.assignments.each do |cp_asgn|
          new_asgn = cp_asgn.clone_to_course( @course.id, @user.id, distance, @app['external_dir'] )
          new_asgn.save
          
          @imported_assignments << new_asgn
        end
      end
    
    end
    
    
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
