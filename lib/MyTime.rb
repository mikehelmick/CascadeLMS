class Time
  
  def nextMonth
    year = self.year
    month = self.month
    
    month = month + 1
    if month == 13
      year = year + 1
      month = 1
    end

    return Time.mktime( year, month )
  end
  
  def prevMonth
    year = self.year
    month = self.month

    month = month - 1
    if month == 0 
      month = 12
      year = year - 1
    end    
    
    return Time.mktime( year, month )
  end
  
  def yearAndMonth
    self.strftime( "%Y%m" )
  end
  
end