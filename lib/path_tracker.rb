require 'uri'
require 'socket'

module PathTracker
  public 

  def track_path
    begin
      referer = @params['referer'] # env['HTTP_REFERER']
      req_uri = @params['doc'] # env['REQUEST_URI']
      
      req_uri = @request.env['HTTP_REFERER'] if req_uri.nil?
      
      req_uri = get_doc_url(req_uri)
      
      size = @params['size']
      colors = @params['colors']
      java = @params['java']
      je = @params['je']
      flash = @params['flash']
              
      env = @request.env.nil? ? {'HTTP_USER_AGENT' => nil, 'HTTP_REFERER' => nil,
        'REMOTE_ADDR' => nil, 'HTTP_ACCEPT_LANGUAGE' => nil, 'REQUEST_URI' => nil} : @request.env
      br = parse_user_agent(env['HTTP_USER_AGENT'])
      subdomain = detect_subdomain
      domain = get_urls_host(referer)
      
      sniff_keywords(domain, subdomain, referer);

      remote_ip = env['HTTP_X_FORWARDED_FOR'] || env['REMOTE_ADDR']
      
      if remote_ip == "127.0.0.1"
        client_country = "localhost"
      else
        client_country = Iptoc.find_by_ip_address(remote_ip)
      end

      RailStat.create("remote_ip" => remote_ip,
                      "country" => client_country,
                      "language" => determine_lang(env['HTTP_ACCEPT_LANGUAGE']),
                      "domain" => domain,
                      "subdomain" => subdomain,
                      "referer" => referer,
                      "resource" => req_uri,
                      "user_agent" => env['HTTP_USER_AGENT'],
                      "platform" => br['platform'],
                      "browser" => br['browser'],
                      "version" => br['version'],
                      "screen_size" => size,
                      "colors" => colors,
                      "java" => java,
                      "java_enabled" => je,
                      "flash" => flash)
    rescue Exception => e
      RAILS_DEFAULT_LOGGER.error("Error on path track #{e.backtrace.join('\n')}" )
    end                  
    ""                
  end
    
  private
    
  def determine_lang(language) 
    ret = "empty"
    unless language.nil? or language == ''
      # Capture up to the first delimiter (, found in Safari)
      begin
        ret = /([^,;]*)/.match(language)[0];
      rescue
      end  
    end
    return ret
  end
    
  def get_urls_host(ref)
    if host = parse_url(ref)
      if host == SITE_NAME
        return nil
      else
        host
      end
    else
      return nil
    end  
  end
  
  def parse_url(arg)
    if arg.nil?
      return nil
    else
      URI::split(arg.gsub(' ','%20'))[2] 
    end
  end
  
  def get_doc_url(arg)
    if arg.nil?
      return nil
    else
      URI::split(arg.gsub(' ','%20'))[5] 
    end
  end
  
  def get_params_url(arg)
    if arg.nil?
      return nil
    else
      URI::split(arg.gsub(' ','%20'))[7] 
    end
  end
  
  def parse_user_agent(ua)
    browser = {'platform' => "unknown", 'browser' => "unknown",
      'version' => "unknown", 'majorver' => "unknown", 'minorver' => "unknown"}
    begin
      # Test for platform
      if ua =~ /Win/i
        browser['platform'] = "Windows";
      elsif ua =~ /Mac/i
        browser['platform'] = "Macintosh";
      elsif ua =~ /Linux/i
        browser['platform'] = "Linux";
      end
      
      
      # Test for browser type
      if ua =~ /Mozilla\/4/i && !ua =~ /compatible/i
        browser['browser'] = "Netscape";
        begin 
          browser['version'] = /Mozilla\/([[:digit:]\.]+)/i.match(ua)[1] 
        rescue 
        end
      end
      if ua =~ /Mozilla\/5/i || ua =~ /Gecko/i
        browser['browser'] = "Mozilla";
        begin 
          browser['version'] = /rv(:| )([[:digit:]\.]+)/i.match(ua)[2]  
        rescue 
        end
      end
      if ua =~ /Safari/i
        browser['browser'] = "Safari";
        browser['platform'] = "Macintosh";
        begin 
          browser['version'] = /Safari\/([[:digit:]\.]+)/i.match(ua)[1]  
        rescue 
        end
        
        if browser['version'] =~ /125/i
          browser['version']   = 1.2;
          browser['majorver']  = 1;
          browser['minorver']  = 2;
        elsif browser['version'] =~ /100/i
          browser['version']   = 1.1;
          browser['majorver']  = 1;
          browser['minorver']  = 1;
        elsif browser['version'] =~ /85/i
          browser['version']   = 1.0;
          browser['majorver']  = 1;
          browser['minorver']  = 0;
        else 
          begin
            if browser['version'].to_i < 85 
              browser['version']   = "Pre-1.0 Beta";
            end
          rescue
          end  
        end
      end
      if ua =~ /iCab/i
        browser['browser'] = "iCab";
        begin 
          browser['version'] = /iCab\/([[:digit:]\.]+)/i.match(ua)[1]  
        rescue 
        end
      end
      if ua =~ /Firefox/i
        browser['browser'] = "Firefox";
        begin 
          browser['version'] = /Firefox\/([[:digit:]\.]+)/i.match(ua)[1]  
        rescue 
        end
      end
      if ua =~ /Firebird/i
        browser['browser'] = "Firebird";
        begin 
          browser['version'] = /Firebird\/([[:digit:]\.]+)/i.match(ua)[1]  
        rescue 
        end
      end
      if ua =~ /Phoenix/i
        browser['browser'] = "Phoenix";
        begin 
          browser['version'] = /Phoenix\/([[:digit:]\.]+)/i.match(ua)[1]  
        rescue 
        end
      end
      if ua =~ /Camino/i
        browser['browser'] = "Camino";
        begin 
          browser['version'] = /Camino\/([[:digit:]\.]+)/i.match(ua)[1]  
        rescue 
        end
      end
      if ua =~ /Chimera/i
        browser['browser'] = "Chimera";
        begin 
          browser['version'] = /Chimera\/([[:digit:]\.]+)/i.match(ua)[1] 
        rescue 
        end
      end
      if ua =~ /Netscape/i
        browser['browser'] = "Netscape";
        begin 
          browser['version'] = /Netscape[0-9]?\/([[:digit:]\.]+)/i.match(ua)[1] 
        rescue 
        end
      end
      if ua =~ /MSIE/i
        browser['browser'] = "IE";
        begin 
          browser['version'] = /MSIE ([[:digit:]\.]+)/i.match(ua)[1] 
        rescue 
        end
      end
      if ua =~ /Opera/i
        browser['browser'] = "Opera";
        begin 
          browser['version'] = /Opera( |\/)([[:digit:]\.]+)/i.match(ua)[1] 
        rescue 
        end
      end
      if ua =~ /OmniWeb/i
        browser['browser'] = "OmniWeb";
        begin 
          browser['version'] = /OmniWeb\/([[:digit:]\.]+)/i.match(ua)[1] 
        rescue 
        end
      end
      if ua =~ /Konqueror/i
        browser['platform'] = "Linux";
        browser['browser'] = "Konqueror";
        begin 
          browser['version'] = /Konqueror\/([[:digit:]\.]+)/i.match(ua)[1] 
        rescue 
        end
      end
      if ua =~ /Crawl/i || ua =~ /bot/i || ua =~ /slurp/i || ua =~ /spider/i
        browser['browser'] = "Crawler/Search Engine";
      end
      if ua =~ /Lynx/i
        browser['browser'] = "Lynx";
        begin 
          browser['version'] = /Lynx\/([[:digit:]\.]+)/i.match(ua)[1] 
        rescue 
        end
      end
      if ua =~ /Links/i
        browser['browser'] = "Links";
        begin 
          browser['version'] = /\(([[:digit:]\.]+)/i.match(ua)[1] 
        rescue 
        end
      end      
      
      # Determine browser versions
      unless browser['browser'] == 'Safari' or browser['browser'] == "unknown" or browser['browser'] == "Crawler/Search Engine" or browser['version'] == "unknown"
        # Make sure we have at least .0 for a minor version
        browser['version'] = (!browser['version']=~/\./ ? "#{browser['version']}.0" : browser['version'])
        
        v = /^([0-9]*).(.*)$/.match(browser['version'])
        begin 
          browser['majorver'] = v[1];
          browser['minorver'] = v[2];
        rescue
        end  
      end
      if browser['version'].nil? or browser['version'] == "" or browser['version'] == '.0'
        browser['version']  = "unknown";
        browser['majorver'] = "unknown";
        browser['minorver'] = "unknown";
      end
    rescue Exception => e
    end
    return browser
  end
  
  public 
  
  def sniff_keywords(domain, subdomain, referer) 
    begin
      searchterms = ''
      uripars = get_params_url(referer) unless referer.nil?
      params = CGI.parse(get_params_url(referer)) if uripars and not(uripars.nil?)
      if domain =~ /google\./i
        # Googles search terms are in "q"
        searchterms = params['q']
      elsif domain =~ /alltheweb\./i
        # All the Web search terms are in "q"
        searchterms = params['q']
      elsif domain =~ /yahoo\./i
        tempwords = referer.scan(/(\/K=)([^\/]*)(\/)/)
        if tempwords and tempwords[0]
          searchterms = tempwords[0][1]
        else
          searchterms = params['va']
        end
      elsif domain =~ /search\.aol\./i
        # Yahoo search terms are in "query"
        searchterms = params['query']
      elsif domain =~ /search\.msn\./i
        # MSN search terms are in "q"
        searchterms = params['q']
      end
      SearchTerm.register(searchterms, domain, subdomain) unless searchterms.nil? or searchterms == ''
    rescue Exception=>ex
      RAILS_DEFAULT_LOGGER.debug("#{ex} - #{ex.backtrace.join("\n\t")}")
    end
  end
  
  private 
  
  def detect_subdomain
    subd = ''
    begin
      subd = ((@request.subdomains and @request.subdomains.first) ? @request.subdomains.first : nil)
    rescue Exception => e
      logger.error("Error on subdomain parse #{e.backtrace.join('\n')}" )
    end
    return subd
  end 
end
