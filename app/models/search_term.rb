class SearchTerm < ActiveRecord::Base
  def self.register(searchterms, domain, subdomain)
    terms = find_all(["domain = ? and subdomain = ? and searchterms = ?", domain, subdomain, searchterms.to_s])
    if terms and terms.size > 0
      terms.each {|term| 
        term.count = term.count + 1
        term.save
      }
    else
      self.create("count"=>1, "searchterms" => searchterms.to_s, "subdomain" => subdomain, 'domain' => domain)  
    end      
  end

  def self.find_grouped(params = {})
    if params[:subdomain].nil?
      SearchTerm.find_by_sql("SELECT searchterms, COUNT(*) AS total FROM search_terms GROUP BY domain, searchterms, count ORDER BY count DESC;")
    else
      SearchTerm.find_by_sql("SELECT searchterms, COUNT(*) AS total FROM search_terms WHERE subdomain = '#{params[:subdomain]}' GROUP BY domain, searchterms, count ORDER BY count DESC;")
    end
  end
end
