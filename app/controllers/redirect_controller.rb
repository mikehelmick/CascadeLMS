class RedirectController < ApplicationController
  
  before_filter :ensure_logged_in
  
  def index
    type = params[:type]
    id = params[:id]
    
    begin
      if ( type.eql?('Assignment') )
        assignment = Assignment.find(id)
        if assignment.quiz.nil?      
          redirect_to :controller => '/assignments', :course => assignment.course, :action => 'view', :id => assignment
        else
          flash[:notice] = "To start the quiz '#{assignment.title}', click the name of the quiz below."
          redirect_to :controller => '/assignments', :course => assignment.course, :action => nil, :id => nil
        end
      elsif ( type.eql?('Post' ) )
        post = Post.find(id)
        redirect_to :controller => '/blog', :course => post.course, :action => 'post', :id => post
      elsif ( type.eql?('Comment') )
        comment = Comment.find(id)
        redirect_to :controller => '/blog', :course => comment.post.course, :action => 'post', :id => comment.post, :anchor => "comment_#{comment.id}"
      elsif ( type.eql?('Document') ) 
        document = Document.find(id)
        if document.folder
          redirect_to :controller => '/documents', :course => document.course, :action => 'index', :id => document
        else
          redirect_to :controller => '/documents', :course => document.course, :action => 'download', :id => document
        end
      else
        redirect_to :controller => '/home', :type => nil, :id => nil   
      end
    rescue
      flash[:badnotice] = "Invalid item requested."
      redirect_to :controller => '/home', :type => nil, :id => nil
    end
    
  end
  
end
