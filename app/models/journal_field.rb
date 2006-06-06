class JournalField < ActiveRecord::Base
  set_primary_key 'assignment_id'
  belongs_to :assignment
end
