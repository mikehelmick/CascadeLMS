class Wiki < ActiveRecord::Base
  
  validates_presence_of :page, :content
  
  belongs_to :course
  belongs_to :user
  
  before_save :transform_markup

  has_one :item, :dependent => :destroy
  
  def Wiki.find_or_create( course, user, page_name )
    cur_page = Wiki.find(:first, :conditions => ["course_id = ? and page = ?", course.id, page_name ], :order => "revision DESC" ) rescue cur_page = nil
    
    if cur_page.nil?
      cur_page = Wiki.new
      cur_page.course = course
      cur_page.content = "This is a new Wiki page named '#{page_name}'."
      cur_page.user = user
      cur_page.revision = 1
      cur_page.page = page_name
      cur_page.save 
    end
    
    return cur_page
  end

  def create_item(link = nil)
    item = Item.new
    item.user_id = self.user_id
    item.course_id = self.course.id
    action = "Created"
    action = "Updated" if self.revision > 0
    item.body = 
        if link.nil?
          "#{action} the wiki page '#{self.page}' in #{self.course.short_description}."
        else
          "#{action} the wiki page '<a href=\"#{link}\">#{self.page}</a>' in #{self.course.short_description}. Revision #{self.revision}."
        end
    item.enable_comments = true
    item.enable_reshare = false
    item.wiki_id = self.id
    item.created_at = self.created_at
    item.public = false
    return item
  end

  def publish(link)
    published = false
    Item.transaction do
      item = self.create_item(link)
      item.save
      item.share_with_course(self.course, self.created_at)
      published = true
    end
    return published
  end

  def clone_to_course(course, user)
    prevWiki = Wiki.find(:first, :conditions => ["course_id = ? and page = ?", course.id, self.page], :order => 'revision desc')
    revision = 1
    revision = prevWiki.revision + 1 unless prevWiki.nil?
    
    new_page = Wiki.new
    new_page.course_id = course.id
    new_page.page = self.page        
    new_page.content = self.content
    new_page.content_html = self.content_html
    new_page.created_at = self.created_at
    new_page.updated_at = self.updated_at
    new_page.user_id = user.id
    new_page.revision = revision
    new_page.user_editable = self.user_editable 
    new_page.save
    return new_page
  end
  
  def transform_markup
	  self.content_html = HtmlEngine.apply_textile( self.content.apply_code_tag )
  end
  
  protected :transform_markup
  
end
