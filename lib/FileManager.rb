class FileManager
  
  @@icons = { 'pdf' => 'page_white_acrobat',
              'mp3' => 'music', 'wav' => 'music', 'acc' => 'music', 'ogg' => 'music',
              'doc' => 'page_white_word',
              'ppt' => 'page_white_powerpoint', 'pps' => 'page_white_powerpoint',
              'xls' => 'page_white_excel',
              'java' => 'page_white_cup', 'jar' => 'page_white_cup',
              'cc' => 'page_white_cplusplus', 'c++' => 'page_white_cplusplus',
              'cpp' => 'page_white_cplusplus',
              'c++' => 'page_white_cplusplus',
              'cs' => 'page_white_csharp',
              'rb' => 'page_white_ruby',
              'c' => 'page_white_c',
              'zip' => 'page_white_compressed', 'gz' => 'page_white_compressed', 'tar' => 'page_white_compressed',
              'jpg' => 'page_white_camera', 'png' => 'page_white_camera',
              'gif' => 'page_white_camera', 'jpeg' => 'page_white_camera' }
     
  @@text_exts = { 'java' => true, 
                  'cc' => true, 
                  'cpp' => true, 
                  'c++' => true, 
                  'cs' => true, 
                  'rb' => true, 
                  'c' => true, 
                  'tex' => true, 
                  'txt' => true, 
                  'readme' => true }
     
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
     'sh' => 'sh',
     'sql' => 'sql'
  }
              
  def FileManager.enscript_language( extension )
    format = @@enscripts[extension]
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
              
  def FileManager.icon( extension ) 
    icn = @@icons[extension]
    icn = 'page_white' if icn.nil?
    return icn
  end
  
  def FileManager.is_text_file( extension ) 
    @@text_exts[extension]
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