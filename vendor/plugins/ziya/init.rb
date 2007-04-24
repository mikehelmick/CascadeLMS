require File.dirname(__FILE__) + '/lib/ziya'    
require File.dirname(__FILE__) + '/lib/ziya_helper'    
require File.dirname(__FILE__) + '/lib/ziya_charting'    

ActionView::Base.send(:include, Ziya::Helper)       