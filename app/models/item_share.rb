class ItemShare < ActiveRecord::Base
    belongs_to :item
    belongs_to :course
    belongs_to :user

    def self.for_course(item, course)
      is = ItemShare.find(:first, :conditions => ["item_id = ? and course_id = ?", item.id, course.id])
      if is.nil?
        is = ItemShare.new
        is.item_id = item.id
        is.course_id = course.id
        is.save
      end
      return is
    end

    def self.for_user(item, user)
      is = ItemShare.find(:first, :conditions => ["item_id = ? and user_id = ?", item.id, user.id])
      if is.nil?
        is = ItemShare.new
        is.item_id = item.id
        is.user_id = user.id
        is.save
      end
      return is
    end
end
