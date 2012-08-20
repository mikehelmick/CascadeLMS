class FileManager
  
  @@icons = { 'pdf' => 'icon-print',
              'mp3' => 'icon-music', 
              'wav' => 'icon-music', 
              'acc' => 'icon-music', 
              'ogg.png' => 'icon-music',
              'mov' => 'icon-film',
              'mp4' => 'icon-film',
              'm4v' => 'icon-film',
              'wmv' => 'icon-film',
              'doc' => 'icon-file',
              'ppt' => 'icon-th-large', 
              'pps' => 'icon-th-large',
              'xls' => 'icon-th-large',
              'java' => 'icon-file', 
              'jar' => 'icon-file',
              'cc' => 'icon-file', 
              'c++' => 'icon-file',
              'cpp' => 'icon-file',
              'c++' => 'icon-file',
              'cs' => 'icon-file',
              'rb' => 'icon-file',
              'c' => 'icon-file',
              'zip' => 'icon-folder-close', 
              'gz' => 'icon-folder-close', 
              'tar' => 'icon-folder-close',
              'jpg' => 'icon-picture', 
              'png' => 'icon-picture',
              'gif' => 'icon-picture', 
              'jpeg' => 'icon-picture',
              'vb' => 'icon-file',
              'xml' => 'icon-file',
              'vm' => 'icon-file',
              'html' => 'icon-file',
              'rhtml' => 'icon-file',
              'properties' => 'icon-file',
              'txt' => 'icon-file',
              'mf' => 'icon-file',
              'jsp' => 'icon-file',
              'ss' => 'icon-file',
              'scm' => 'icon-file' }
     
  @@text_exts = { 'java' => true, 
                  'cc' => true, 
                  'cpp' => true, 
                  'c++' => true, 
                  'cs' => true, 
                  'rb' => true, 
                  'c' => true, 
                  'tex' => true, 
                  'txt' => true, 
                  'readme' => true,
                  'vb' => true,
                  'jsp' => true,
                  'vm' => true,
                  'mf' => true,
                  'properties' => true,
                  'xml' => true,
                  'html' => true,
                  'rhtml' => true,
                  'sh' => true,
                  'ss' => true,
                  'scm' => true,
                  'h' => true,
                  'm' => true }
     
  @@enscripts = {    
     'asm' => 'asm',
     's' => 'asm',
     'c' => 'c',
     'cpp' => 'cpp',
     'c++' => 'cpp',
     'cxx' => 'cpp',
     'cc' => 'cpp',
     'html' => 'html',
     'htm' => 'html',
     'rhtml' => 'html',
     'xml' => 'html',
     'idl' => 'idl',
     'java' => 'java',
     'aj' => 'java',
     'js' => 'javascript',
     'm' => 'objc',
     'pas' => 'pascal',
     'pl' => 'perl',
     'py' => 'python',
     'sc' => 'scheme',
     'ss' => 'scheme',
     'scm' => 'scheme',
     'sh' => 'sh',
     'sql' => 'sql',
     'jsp' => 'html',
     'vb' => 'vba',
     'vm' => 'html',
     'sql' => 'sql'
  }
  
  def FileManager.text_extension_map
    ext = Hash.new
    @@text_exts.keys.each { |k| ext[k] = k }
    return ext
  end
              
  def FileManager.enscript_language( extension )
    format = @@enscripts[extension.downcase] rescue nil
    format = 'java' if format.nil?
    return format
  end
  
  def FileManager.format_file( enscript, path, extension )
    ## to be moved
    command = "#{enscript} -C --pretty-print=#{FileManager.enscript_language(extension)} --language=html --color -p- -B #{path}"
    formatted =`#{command}`
    
    lines = Array.new
    pull = false
    formatted.each_line do |line|
      if !line.upcase.index('<PRE>').nil?
        pull = true
      elsif !line.upcase.index('</PRE>').nil? && line.upcase.index('</PRE>') > 0 ## no newline after last line
        lines << line[0..-6].chomp.gsub(/  /, "&nbsp;&nbsp;" ).gsub(/\t/,"&nbsp;&nbsp;&nbsp;&nbsp;")
        pull = false
      elsif !line.upcase.index('</PRE>').nil?
        pull = false
      elsif pull
        lines << line.chomp.gsub(/  /, "&nbsp;&nbsp;" ).gsub(/\t/,"&nbsp;&nbsp;&nbsp;&nbsp;")
      end
    end
    ## end to be moved
  
    return lines
  end
  
  def FileManager.java_banned( path, banned )
    # convert to array if not already
    banned = banned.split(" ") if banned.class.to_s.eql?("String")
    msg = ""
    
    line_num = 1
    if path.reverse[0..4].eql?("avaj.")
      File.open( path ).each do |line|
        banned.each do |str|

          unless line.index( str ).nil?
            msg = "#{msg}\nline #{line_num}: Contains disallowed string '#{str}'"
            
          end
        end
        line_num = line_num.next
      end
    end
    return msg
  end
  
  def FileManager.java?( path )
    return path.downcase.reverse[0..4].eql?("avaj.")
  end
  
  def FileManager.java_main?( path )
    rtn = false
    if path.reverse[0..4].eql?("avaj.")
      File.open( path ).each do |line|
        public_index = line.index('public') 
        static_index = line.index('static') 
        void_index = line.index('void') 
        main_index = line.index('main') 
        #puts "p:#{public_index} s:#{static_index} v:#{void_index} m:#{main_index} line:#{line}"
        # line must contain all of these
        if( !public_index.nil? && !static_index.nil? && !void_index.nil? && !main_index.nil? &&
            static_index > public_index && void_index > public_index &&
            main_index > public_index && main_index > static_index && main_index > void_index )
          rtn = true
        end
      end
    end
    return rtn
  end
              
  def FileManager.icon( extension ) 
    icn = @@icons[extension.downcase] rescue nil
    icn = 'page_white.png' if icn.nil?
    return icn
  end
  
  def FileManager.is_text_file( extension ) 
    @@text_exts[extension.downcase] rescue nil
  end
  
  def FileManager.base_part_of(file_name)
    name = File.basename(file_name)
    name.gsub(/[^\w._-]/, '')
  end
  
  def FileManager.size_text( size )
    if size.to_i < 1024
      "#{size}b"
    elsif size.to_i < 1024000
      "#{format('%0.2f',size.to_f/1024)}Kb"
    else
      "#{format('%0.2f',size.to_f/1024000)}Mb"
    end
  end
  
end