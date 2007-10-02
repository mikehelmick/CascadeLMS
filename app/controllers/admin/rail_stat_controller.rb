require_dependency 'path_tracker'

class Admin::RailStatController < ApplicationController
  include PathTracker
  
  before_filter :ensure_logged_in, :ensure_admin, :extract_subdomain

   layout 'rail_stat'

  def index
    redirect_to(:action=>'path')
  end

  def path
    @ordered_resources, @orarr = RailStat.get_ordered40resources(@subdomain)

    @number_hits = (@params['nh'] or not @params['nh'].nil?) ? @params['nh'].to_i : 50
    @include_search_engines = ((@params['ise'] == '' or @params['ise'] == "1") ? 1 : 0)

    @count_totals = RailStat.resource_count_totals    
    @paths = RailStat.find_all_by_flag(@include_search_engines == 0, @number_hits, @subdomain)
    
    # Experiments:
    @total_hits = RailStat.count_hits(:subdomain => @subdomain)
    @unique_hits = RailStat.count_hits(:unique, :subdomain => @subdomain)
  end
  
  def hits
    @lastweek = RailStat.find_by_days(:subdomain=>@subdomain, :days => 7)
    @first_hit = RailStat.find_first_hit(:subdomain=>@subdomain)
    @total_hits = RailStat.count_hits(:subdomain => @subdomain)
    @unique_hits = RailStat.count_hits(:unique, :subdomain => @subdomain)
    n = Time.now
    d = Date.new(n.year, n.month, n.day)
    @today_total = RailStat.count_hits(:subdomain => @subdomain, :date => d)
    @today_unique = RailStat.count_hits(:unique, :subdomain => @subdomain, :date => d)
    @past_7_total = RailStat.count_hits(:subdomain => @subdomain, :past_days => 7)
    @past_7_unique = RailStat.count_hits(:unique, :subdomain => @subdomain,  :past_days => 7)
  end
  
  def platform
    @total_hits = RailStat.count_hits(:subdomain => @subdomain)
    @platforms = RailStat.find_by_platform(:subdomain => @subdomain)
    @browsers = RailStat.find_by_browser(:subdomain => @subdomain)
  end
  
  def lang
    @total_hits = RailStat.count_hits(:subdomain => @subdomain)
    @languages = RailStat.find_by_language(:subdomain => @subdomain)
    @countries = RailStat.find_by_country(:subdomain => @subdomain)    
  end
  
  def refs
    @refs = RailStat.find_by_domain(:subdomain => @subdomain)
    @searchterms = SearchTerm.find_grouped(:subdomain => @subdomain)
  end
  
  def other
    #hits = RailStat.count_hits(:subdomain => @subdomain)
    #@total_hits = RailStat.count_hits()
    
    @flash_clients = RailStat.find_by_client(:type => "flash", :subdomain => @subdomain)
    @flash_clients_total = @flash_clients.inject(0) {|sum, result| sum + result.total.to_i} 				

    @java_clients = RailStat.find_by_client(:type => "java_enabled", :subdomain => @subdomain)
    @java_clients_total = @java_clients.inject(0) {|sum, result| sum + result.total.to_i}
    
    @javascript_clients = RailStat.find_by_client(:type => "java", :subdomain => @subdomain)
    @javascript_clients_total = @javascript_clients.inject(0) {|sum, result| sum + result.total.to_i}
    
    @width_of_clients = RailStat.find_by_client(:type => "screen_size", :subdomain => @subdomain)
    @width_of_clients_total = @width_of_clients.inject(0) {|sum, result| sum + result.total.to_i}
    
    @colors_of_clients = RailStat.find_by_client(:type => "colors", :subdomain => @subdomain)
    @colors_of_clients_total = @colors_of_clients.inject(0) {|sum, result| sum + result.total.to_i}
  end

  def tracker_js
    if @request.env['HTTP_REFERER'] and @request.env['HTTP_REFERER'].include?(request.host)
    str = <<-JSDATA
    c=0;
    s=0;
    n=navigator;
    d=document;
    plugin=(n.mimeTypes&&n.mimeTypes["application/x-shockwave-flash"])?n.mimeTypes["application/x-shockwave-flash"].enabledPlugin:0;
    if(plugin) {
      w=n.plugins["Shockwave Flash"].description.split("");
      for(i=0;i<w.length;++i) { if(!isNaN(parseInt(w[i]))) { f=w[i];break; } }
    } else if(n.userAgent&&n.userAgent.indexOf("MSIE")>=0&&(n.appVersion.indexOf("Win")!=-1)) {
      d.write('<script language="VBScript">On Error Resume Next\\nFor f=10 To 1 Step-1\\nv=IsObject(CreateObject("ShockwaveFlash.ShockwaveFlash."&f))\\nIf v Then Exit For\\nNext\\n</script>');
    } if(typeof(top.document)=="object"){
      t=top.document;
      rf=escape(t.referrer);
      pd=escape(t.URL);
    } else {
      x=window;
      for(i=0;i<20&&typeof(x.document)=="object";i++) { rf=escape(x.document.referrer); x=x.parent; }
      pd=0;
    }
    d.write('<script language="JavaScript1.2">c=screen.colorDepth;s=screen.width;</script>');
    if(typeof(f)=='undefined') f=0;
    d.write('<a href="/" target="_blank"><img src="/rail_stat/track?size='+s+'&colors='+c+'&referer='+rf+'&java=1&je='+(n.javaEnabled()?1:0)+'&doc='+escape(d.URL)+'&flash='+f+'" border="0" width="1" height="1"></a><br>');
    JSDATA
    else
      str = ""
    end
    render_text(str)
  end
  
  def track
    track_path
    @response.headers['Pragma'] = ' '
    @response.headers['Cache-Control'] = ' '
    @response.headers['Content-Length'] = 68
    @response.headers['Accept-Ranges'] = 'bytes'
    @response.headers['Content-type'] = 'image/gif'
    @response.headers['Content-Disposition'] = 'inline'
    File.open("#{RAILS_ROOT}/public/images/railstat/1pxtr.gif", 'rb') { |file| render :text => file.read }
  end


  private
  def extract_subdomain
    @subdomain = ((@request.subdomains and @request.subdomains.first) ? @request.subdomains.first : nil)
  end

end

