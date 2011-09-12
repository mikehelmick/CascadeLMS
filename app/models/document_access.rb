class DocumentAccess < ActiveRecord::Base
  belongs_to :document
  belongs_to :user
  belongs_to :course

  def self.user_map_for_document(document)
    das = DocumentAccess.find(:all, :conditions => ["document_id = ?", document.id], :order => "created_at asc")
    doc_access_map = Hash.new
    das.each do |da|
      doc_access_map[da.user_id] = Array.new if doc_access_map[da.user_id].nil?
      doc_access_map[da.user_id] << da
    end
    return doc_access_map
  end
end
