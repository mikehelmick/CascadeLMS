class Status < ActiveRecord::Base

  def self.get_status(name)
    begin
      status = Status.find(:first, :conditions => ["name = ?", name])
      raise 'not_found' if status.nil?
      return status
    rescue
      s = Status.new
      s.name = name
      s.value = ""
      return s
    end
  end
end
