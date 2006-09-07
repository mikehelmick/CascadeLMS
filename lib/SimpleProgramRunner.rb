require 'date'

class SimpleProgramRunner
  
  def initialize( programming_language, directory, filename, logger = nil )
    @pl = programming_language
    @directory = directory
    @filename = filename
    @logger = logger
    
    @compile_success = false
  end
  
  def compile()
    if ( @pl.enable_compile_step )
      cleanup_generated_file
      
      command = "cd #{@directory}; #{@pl.compile_command}"
      command = escape_commands( command, @filename )
      log( "SimpleProgramRunner: #{command}" )
      
      compile_out = `#{command} 2>&1`
  
      unless @pl.executable_name.nil? || @pl.executable_name.eql?('')
        verify_command = escape_commands( "cd #{@directory}; ls -1 #{@pl.executable_name}", @filename )
        verify_out = `#{verify_command}`
        log( "SimpleProgramRunner: #{verify_command}" )
        
        @compile_success = ! verify_out.index( escape_commands( @pl.executable_name, @filename) ).nil?
      else
        @compile_success = true
      end
  
      return compile_out
    else
      @compile_success = true
    end
    return ''
  end
  
  def did_compile?
    @compile_success
  end
  
  def execute( args = '', standard_in = nil )
    if did_compile?
      command = "cd #{@directory}; #{@pl.execute_command} #{args}"
      
      stdin_fn = nil
      unless standard_in.nil?
        stdin_fn = "#{Time.now.to_f}_standard_in.private.txt"
        file = File.new("#{@directory}/#{stdin_fn}",  "w")
        file << standard_in
        file << "\n"
        file.close
        
        command = "#{command} < #{stdin_fn}"
      end
      
      command = escape_commands( command, @filename )
      log( "SimpleProgramRunner: #{command}" )
      
      run_out = `#{command} 2>&1`
      
      cleanup_generated_file( stdin_fn )
      return run_out
    else
      return '!!!!DID NOT EXECUTE!!!!'
    end
  end
  
  private
  
  def cleanup_generated_file( extra_file = nil )
    command = "cd #{@directory}; rm #{@pl.executable_name}"
    command = escape_commands( command, @filename )
    `#{command} 2>&1`
    
    unless extra_file.nil?
      command = "cd #{@directory}; rm #{extra_file}"
      `#{command} 2>&1`
    end
    
  end
  
  def escape_commands( command, filename )
    rtn = command.gsub(/\{\:mainfile\}/, filename )
    rtn = rtn.gsub(/\{\:basename\}/, without_extension(filename) )
    
    return rtn
  end
  
  
  def log( line )
    @logger.info( line ) unless @logger.nil?
  end
  
  def without_extension( filename )
    filename[0...filename.rindex('.')]
  end
  
end