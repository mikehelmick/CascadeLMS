class RailStat < ActiveRecord::Base
  
  # Method returns paths hash with to 40 paths whith value = top index (1..40)
  
  def RailStat.resource_count_totals()
    find_by_sql("SELECT resource, COUNT(resource) AS requests, max(created_at) AS last_access FROM rail_stats GROUP BY resource ORDER BY requests DESC")
  end
  
  def RailStat.find_all_by_flag(include_search_engine, number_hits, subdomain)
    if subdomain.nil?
      if include_search_engine
        find(:all, :conditions => "browser <> 'Crawler/Search Engine'", :order => "created_at desc", :limit => number_hits)
      else
        find(:all, :order => "created_at desc", :limit => number_hits)
      end
    else
      if include_search_engine
        find(:all, :conditions => ["subdomain = ? and browser <> 'Crawler/Search Engine'", subdomain], :order => "created_at desc", :limit => number_hits)
      else
        find(:all, :conditions => ["subdomain = ?", subdomain], :order => "created_at desc", :limit => number_hits)
      end
    end
  end  
  
####
#
# Misc Methods (What are these?)
#
####
  
  def marked?
    (@marked and @marked == true)
  end
  
  def mark
    @marked = true
  end
  
  def RailStat.get_ordered40resources(subdomain)
      ordered_resources = []
      if subdomain.nil?
        find_by_sql("SELECT resource, COUNT(resource) AS requests,  max(created_at) AS created_at " +
                      "FROM rail_stats " +
                      "GROUP BY resource ORDER BY created_at DESC LIMIT 40").each { |row|
          ordered_resources << row
        }
      else
        find_by_sql("SELECT resource, COUNT(resource) AS requests,  max(created_at) AS created_at " +
                      "FROM rail_stats WHERE subdomain = '#{subdomain}' " +
                      "GROUP BY resource ORDER BY created_at DESC LIMIT 40").each { |row|
          ordered_resources << row
        }
      end
      i = 1
      orh = {}
      ordered_resources = ordered_resources.sort {|x,y| y['requests'].to_i <=> x['requests'].to_i }
      ordered_resources.each { |row|
        orh[row['resource']] = i
        i = i + 1
      } unless ordered_resources.nil? or ordered_resources.size == 0
      return orh, ordered_resources
  end
  
  def datetime
      Time.at(self.created_at)
  end

####
#
# Counters
#
####

  ###
  # count_hits
  #
  # parameters:
  #   :unique => get stats for distinct remote IPs
  #   :subdomain => restrict results to a single subdomain
  #   :date => restrict results to a single date
  #
  # examples:
  #   RailStat.count_hits : returns stats for all hits
  #   RailStat.count_hits(:unique) : returns stats for only unique IPs
  #   RailStat.count_hits(:date => d) : returns stats for the date 'd'
  #   RailStat.count_hits(:unique, :subdomain => "mydomain", :date => d) : returns stats for unique IPs accessing the specified subdomain on the date 'd'
  ###

  def RailStat.count_hits(*params)
    
    query = "select"
    where = ""
    
    if params.include?(:unique)
      query << " count(distinct remote_ip)"      
    else
      query << " count(*)"
    end
          
    query << " as hits from rail_stats"
    
    if params.size == 1
      if params[0].class == Hash
        options = params[0]
      end
    elsif params.size == 2
      options = params[1]
    end
    
    if options    
      if options[:subdomain]
        where << " subdomain = '#{options[:subdomain]}'"
      end
      
      if options[:subdomain] and (options[:date] or options[:past_days])
        where << " AND"
      end
      
      if options[:date]
        where << " created_on = '#{options[:date]}'"
      elsif options[:past_days]
        where << " created_on >= '#{(Time.now - options[:past_days]*24*60*60).strftime("%Y-%m-%d")}'"
      end
    end
    
    query << " where " << where if where != ""
    query << ";"
    
    find_by_sql(query)[0]['hits'].to_i
       
  end

  
####
#
# Finders
#
####
  
  ##
  #  find_by_days: Find the hits in the specified previous X days. Default is 7 days.
  ##  
  def RailStat.find_by_days(params = {})
    params[:days] = 7 unless params[:days]
    query = "SELECT created_on, COUNT(*) AS total_hits, COUNT(DISTINCT remote_ip) AS unique_hits FROM rail_stats WHERE created_on >= '#{(Time.now - params[:days]*24*60*60).strftime("%Y-%m-%d")}'"    
    query << " AND subdomain = '#{params[:subdomain]}'" if params[:subdomain]
    query << " GROUP BY created_on;"
    find_by_sql(query)
  end
  
  ##
  #  find_first_hit: What is this used for?
  ##  
  def RailStat.find_first_hit(params = {})
    if params[:subdomain].nil?
    	find(:first, :order => "created_at ASC")
    else
    	find(:first, :conditions => ["subdomain = ?", params[:subdomain]], :order => "created_at ASC")
    end
  end
  
  def RailStat.find_by_platform(params = {})
    if params[:subdomain].nil?
      find_by_sql("SELECT platform, COUNT(platform) AS total " +
                            "FROM rail_stats " +
                            "GROUP BY platform " +
                            "ORDER BY total DESC; ")
    else
      find_by_sql("SELECT platform, COUNT(platform) AS total " +
                            "FROM rail_stats " +
                            "WHERE subdomain = '#{params[:subdomain]}' " +
                            "GROUP BY platform " +
                            "ORDER BY total DESC; ")
    end
  end  
  
  def RailStat.find_by_browser(params = {})
      if params[:subdomain].nil?
        find_by_sql("SELECT browser, version, COUNT(*) AS total " +
                              "FROM rail_stats " +
                              "GROUP BY browser, version " +
                              "ORDER BY total DESC; ")
      else
        find_by_sql("SELECT browser, version, COUNT(*) AS total " +
                              "FROM rail_stats " +
                              "WHERE subdomain = '#{params[:subdomain]}'" +
                              "GROUP BY browser, version " +
                              "ORDER BY total DESC; ")
      end
  end
  
  def RailStat.find_by_language(params = {})
      if params[:subdomain].nil?
        find_by_sql("SELECT language, COUNT(*) AS total " +
                              "FROM rail_stats " +
                              "WHERE language != '' and language is not null and language != 'empty' " +
                              "GROUP BY language " +
                              "ORDER BY total DESC; ")
      else
        find_by_sql("SELECT language, COUNT(*) AS total " +
                              "FROM rail_stats " +
                              "WHERE language != '' and language is not null and language != 'empty' and subdomain = '#{params[:subdomain]}'" +
                              "GROUP BY language " +
                              "ORDER BY total DESC; ")
      end
  end
  
  def RailStat.find_by_country(params = {})
      if params[:subdomain].nil?
        find_by_sql("SELECT country, COUNT(*) AS total " +
                              "FROM rail_stats " +
                              "WHERE country != '' and country is not null " +
                              "GROUP BY country " +
                              "ORDER BY total DESC; ")
      else
        find_by_sql("SELECT country, COUNT(*) AS total " +
                              "FROM rail_stats " +
                              "WHERE country != '' and country is not null and subdomain = '#{params[:subdomain]}'" +
                              "GROUP BY country " +
                              "ORDER BY total DESC; ")
      end
    end
    
    def RailStat.find_by_domain(params = {})
      if params[:subdomain].nil?
        find_by_sql("SELECT domain, referer, resource, COUNT(domain) AS total " +
                      "FROM rail_stats " +
                      "WHERE domain != '' " +
                      "GROUP BY domain, referer, resource " +
                      "ORDER BY total DESC; ")
      else
        find_by_sql("SELECT domain, referer, resource, COUNT(domain) AS total " +
                      "FROM rail_stats " +
                      "WHERE domain != '' and subdomain = '#{params[:subdomain]}'" +
                      "GROUP BY domain, referer, resource " +
                      "ORDER BY total DESC; ")
      end
  end

  def RailStat.find_by_client(params = {})
    
    
    if params[:subdomain].nil?
      results = find_by_sql("SELECT #{params[:type]}, COUNT(*) AS total " +
                    "FROM rail_stats " +
                    "GROUP BY #{params[:type]} " +
                    "ORDER BY total DESC; ")
    else
      results = find_by_sql("SELECT #{params[:type]}, COUNT(*) AS total " +
                    "FROM rail_stats " +
                    "WHERE subdomain = '#{params[:subdomain]}'" +
                    "GROUP BY #{params[:type]} " +
                    "ORDER BY total DESC; ")
    end
  end
end
