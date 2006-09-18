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
  
end