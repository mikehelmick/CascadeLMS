class Public::RedirectController < ApplicationController
  
  def index
    type = params[:type]
    id = params[:id]
    
    begin
      if ( type.eql?('Assignment') )
        assignment = Assignment.find(id)
        redirect_to :controller => '/public/assignments', :course => assignment.course, :action => 'view', :id => assignment
      elsif ( type.eql?('Post' ) )
        post = Post.find(id)
        redirect_to :controller => '/public/blog', :course => post.course, :action => 'post', :id => post
      elsif ( type.eql?('Document') ) 
        document = Document.find(id)
        redirect_to :controller => '/public/documents', :course => document.course, :action => 'download', :id => document
      else
        redirect_to :controller => '/public', :type => nil, :id => nil   
      end
    rescue
      flash[:badnotice] = "Invalid item requested."
      redirect_to :controller => '/public', :type => nil, :id => nil
    end
    
  end
  
end
