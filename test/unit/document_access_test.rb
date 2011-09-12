require File.dirname(__FILE__) + '/../test_helper'

class DocumentAccessTest < ActiveSupport::TestCase

  fixtures :document_accesses
  fixtures :documents
  fixtures :users
  
  def test_log
    doc = Document.find(1)
    user = User.find(1)

    assert doc.log_access(user)

    da_from_db = DocumentAccess.find(:all, :conditions => ["document_id = ? and user_id = ? and course_id = ?", doc.id, user.id, doc.course_id])
    assert 1 == da_from_db.size
  end

  def test_map
    doc = Document.find(2)

    map = DocumentAccess.user_map_for_document(doc)
    assert map.size == 2

    ## check map sizes
    assert map[1].size == 2
    assert map[2].size == 1
  end
end
