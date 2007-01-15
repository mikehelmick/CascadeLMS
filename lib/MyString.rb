class String
  
  def to_html
     html = ""
     0.upto(self.size-1) do |i|
      str = self[i...i+1]
      if str.eql?("\n")
        html << "<br/>"
      elsif str.eql?(" ")
        html << "&nbsp;"
      else 
        html << str
      end
    end
    return html
  end
  
  def newline_to_break
     html = ""
     0.upto(self.size-1) do |i|
      str = self[i...i+1]
      if str.eql?("\n")
        html << "<br/>"
      else 
        html << str
      end
    end
    return html    
  end
  
  def apply_code_tag
    output = self
    # transform others
	  code_s = output.index(/\[code\]/)
	  code_e = output.index(/\[\/code\]/, code_s ) unless code_s.nil?
	  while ( !code_s.nil? && !code_e.nil? && code_e > code_s )
	    # convert newlines to breaks
	    temp = output[0...code_s] + '<div class="code">'
	    temp = temp + output[code_s+6...code_e].gsub(/\t/,'&nbsp;&nbsp;').gsub(/ /,'&nbsp;').gsub(/\n/,"<br/>\n")
	    temp = temp + '</div>' + output[code_e+7..-1] 
	    output = temp
	    
	    code_s = output.index(/\[code\]/)
  	  code_e = output.index(/\[\/code\]/, code_s ) unless code_s.nil?
    end
    
    return output
  end
  
  def apply_quote_tag
    output = self
    # transform others
	  code_s = output.index(/\[quote\]/)
	  code_e = output.index(/\[\/quote\]/, code_s ) unless code_s.nil?
	  while ( !code_s.nil? && !code_e.nil? && code_e > code_s )
	    # convert newlines to breaks
	    temp = output[0...code_s] + '<div class="quote">'
	    temp = temp + output[code_s+7...code_e]
	    temp = temp + '</div>' + output[code_e+8..-1] 
	    output = temp
	    
	    code_s = output.index(/\[quote\]/)
  	  code_e = output.index(/\[\/quote\]/, code_s ) unless code_s.nil?
    end
    
    return output
  end
  
end