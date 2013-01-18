class Status < ActiveRecord::Base

  def self.get_status(name)
    begin
      return Status.find(:first, :conditions => ["name = ?", name])
    rescue
      s = Status.new
      s.name = name
      s.value = ""
      return s
    end
  end
end
