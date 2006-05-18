
class HtmlEngine
  
  def self.apply_textile( txt )
    return "" if txt.blank?
    txt = RedCloth.new(txt, []).to_html(:textile)    
    return txt
  end

end
