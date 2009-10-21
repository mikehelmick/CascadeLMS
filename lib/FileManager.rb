class FileManager
  
  @@icons = { 'pdf' => 'page_white_acrobat.png',
              'mp3' => 'music.png', 
              'wav' => 'music.png', 
              'acc' => 'music.png', 
              'ogg.png' => 'music.png',
              'mov' => 'film.png',
              'mp4' => 'film.png',
              'm4v' => 'film.png',
              'wmv' => 'film.png',
              'doc' => 'page_white_word.png',
              'ppt' => 'page_white_powerpoint.png', 
              'pps' => 'page_white_powerpoint.png',
              'xls' => 'page_white_excel.png',
              'java' => 'page_white_cup.png', 
              'jar' => 'page_white_cup.png',
              'cc' => 'page_white_cplusplus.png', 
              'c++' => 'page_white_cplusplus.png',
              'cpp' => 'page_white_cplusplus.png',
              'c++' => 'page_white_cplusplus.png',
              'cs' => 'page_white_csharp.png',
              'rb' => 'page_white_ruby.png',
              'c' => 'page_white_c.png',
              'zip' => 'page_white_compressed.png', 
              'gz' => 'page_white_compressed.png', 
              'tar' => 'page_white_compressed.png',
              'jpg' => 'page_white_camera.png', 
              'png' => 'page_white_camera.png',
              'gif' => 'page_white_camera.png', 
              'jpeg' => 'page_white_camera.png',
              'vb' => 'page_white_visualstudio.png',
              'xml' => 'page_white_code.png',
              'vm' => 'page_white_code.png',
              'html' => 'page_white_code.png',
              'rhtml' => 'page_white_ruby.png',
              'properties' => 'page_white_gear.png',
              'rb' => 'page_white_ruby.png',
              'txt' => 'page_white_text.png',
              'mf' => 'page_white_text.png',
              'jsp' => 'script_code.png',
              'ss' => 'page_white_code_red.png',
              'scm' => 'page_white_code_red.png' }
     
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
    format = @@enscripts[extension.downcase]
    format = 'java' if format.nil?
    return format
  end
  
  def FileManager.format_file( enscript, path, extension )
    ## to be moved
    command = "#{enscript} -C --pretty-print=#{FileManager.enscript_language(extension.downcase)} --language=html --color -p- -B #{path}"
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
    icn = @@icons[extension.downcase]
    icn = 'page_white.png' if icn.nil?
    return icn
  end
  
  def FileManager.is_text_file( extension ) 
    @@text_exts[extension.downcase]
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