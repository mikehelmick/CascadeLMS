class String
  def format_autocomplete
    return self.gsub('"', "'").gsub("'","\\'").gsub('&', '&amp;')
  end
  
  def to_html
     html = ""
     addOne = false
     0.upto(self.size-1) do |i|
      str = self[i...i+1]
      if str.eql?("\n")
        html << "<br/>"
      elsif str.eql?(" ") && self[i+1...i+2].eql?(" ")
        html << "&nbsp;"
        addOne = true
      elsif str.eql?(" ") && addOne
        html << "&nbsp;"
        addOne = false
      else 
        html << str
      end
    end
    return html
  end
  
  def non_span_space_convert
    html = self.to_html
    html.gsub(/<span&nbsp;class=/,"<span class=")
  end

  def newlines_to_space
    return self.gsub(/\n/,' ').gsub(/\r/,'')
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

  # Turn <pre></pre> into [code][/code]
  # In that section Revert &gt and &lt commands inserted by the browser
  # Remove all <br/> since newlines will be preserved when rendered
  def turn_pre_to_code
    output = self

    pre_s = output.index(/\<pre\>/)
    pre_e = output.index(/\<\/pre\>/, pre_s) unless pre_s.nil?
    while (!pre_s.nil? && !pre_e.nil? && pre_e > pre_s)
      # turn these into [code] tags
      temp = output[0...pre_s] + '[code]'
      temp = temp + output[pre_s+5...pre_e].gsub('&gt;', '>').gsub('&lt;', '<').gsub('<br/>', '').gsub('<br />', '')
      temp = temp + '[/code]' + output[pre_e+6..-1]
      output = temp

      pre_s = output.index(/\<pre\>/)
      pre_e = output.index(/\<\/pre\>/, pre_s) unless pre_s.nil?
    end
    return output
  end
  
  def apply_code_tag
    output = self.turn_pre_to_code()
    # transform others
	  code_s = output.index(/\[code\]/)
	  code_e = output.index(/\[\/code\]/, code_s ) unless code_s.nil?
	  while ( !code_s.nil? && !code_e.nil? && code_e > code_s )
	    # convert newlines to breaks
	    temp = output[0...code_s] + '<pre class="prettyprint linenums">'
	    temp = temp + output[code_s+6...code_e].gsub(/\t/,'    ') #.gsub(/  /,'&nbsp; ') #.gsub(/\n/,"<br/>\n")
	    temp = temp + '</pre>' + output[code_e+7..-1] 
	    output = temp
	    
	    code_s = output.index(/\[code\]/)
  	  code_e = output.index(/\[\/code\]/, code_s ) unless code_s.nil?
    end
    
    return output
  end

  def remove_breaks_from_pre
    output = self

    pre_s = output.index(/\<pre/)
    pre_se = output.index(/\>/, pre_s) unless pre_s.nil?
    pre_e = output.index(/\<\/pre\>/, pre_se) unless pre_s.nil?
    while (!pre_s.nil? && !pre_se.nil? && !pre_e.nil? && pre_e > pre_s)
      # Strip breaks, this code is naturally broken with newlines
      temp = output[0..pre_se]
      temp = temp + output[pre_se+1...pre_e].gsub(/\<br\/\>/, '').gsub(/\<br \/\>/, '').gsub(/\<br\>/, '\n')
      temp = temp + output[pre_e..-1]
      output = temp

      pre_s = output.index(/\<pre/, pre_se)
      pre_se = output.index(/\>/, pre_s) unless pre_s.nil?
      pre_e = output.index(/\<\/pre\>/, pre_se) unless pre_s.nil?
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

  def apply_markup
    # Removed - remove_breaks_from_pre(). Of course this doesn't impact strings already translated
    return HtmlEngine.apply_textile(self.apply_code_tag)
  end
end
