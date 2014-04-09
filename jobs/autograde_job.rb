require 'application_controller'
require 'yaml'
require 'erb'
require 'text_diff'
require 'redcloth'

# Class that encapsualtes the autograding of a submission
class AutogradeJob 
  
  def initialize( gradeQueueId )
    @gradeQueueId = gradeQueueId
  end
  
  def run_pmd( queue, user_turnin, dir, directories, app )
    if user_turnin.assignment.auto_grade_setting.check_style?
       jars = "#{ApplicationController.root_dir}/java/#{app['pmd_libs'].split(' ').join(":#{ApplicationController.root_dir}/java/")}"
       command = "#{app['java']} -cp #{jars} #{app['pmd_main']} "
       
       # get files and delete old results
       files = Array.new
       user_turnin.user_turnin_files.each do |utf|
         if utf.filename.reverse[0..4].eql?('avaj.')
           files << "#{app['external_dir']}#{dir}#{utf.full_filename(directories)}"
           FileStyle.delete_all( "user_turnin_file_id = #{utf.id}")
         end
       end
       
       command = "#{command} #{files.join(' ')}"
       puts "SHELL (#{queue.id}): #{command}"
       
       retry_count = 0
       result = `#{command} `
       
       while (result.nil? || result.eql?('')) && retry_count < 10
         puts "RESULTS (#{queue.id}): EMPTY - RETRYING #{retry_count}"
         
         sleep(2)
         
         result = `#{command} `
         retry_count = retry_count.next
       end
       puts "RESULTS (#{queue.id}): #{result}"
      
       #### Parse results
       yaml_res = YAML.load( result )
       
       if yaml_res.nil?
         yaml_res = Array.new
       end
       
       # get the PMD settings
       puts "ROGER ONE"
       
       checks = Hash.new
       filter = Hash.new
       user_turnin.assignment.assignment_pmd_settings.each do |pmd|
         if !pmd.enabled
           filter[pmd.style_check.name] = true
         end
         checks[pmd.style_check.name] = pmd.style_check
       end
       
       puts "ROGER TWO"
        
       count = 0
       ## ERROR ON THIS LINE
       while !yaml_res["violation#{count}"].nil?
         summary = yaml_res["violation#{count}"]
         
         filename = summary['filename']
         user_turnin.user_turnin_files.each do |utf|
           if filename.eql?( "#{app['external_dir']}#{dir}#{utf.full_filename(directories)}" )
             puts( "(#{count}) #{summary['rule_name']} in file #{filename}")
             
             violation = FileStyle.new
             violation.user_turnin_file = utf
             
             violation.begin_line    = summary['begin_line']
             violation.begin_column  = summary['begin_column']
             violation.end_line      = summary['end_line']
             violation.end_column    = summary['end_column']
             violation.package       = summary['package']
             violation.class_name    = summary['class']
             violation.message       = summary['message']
             violation.style_check   = checks[ summary['rule_name'] ]
             violation.suppressed = ! filter[ summary['rule_name'] ].nil?
             
             violation.save
             puts("SAVED VIOLATION")
           end
         end
         
# finalResults.append("  abs_path: " + args[i] + "\n" );
# finalResults.append("  filename: " + rn.getFilename() + "\n" );
# finalResults.append("  begin_line: " + rn.getBeginLine() + "\n" );
# finalResults.append("  begin_column: " + rn.getBeginColumn() + "\n" );
# finalResults.append("  end_line: " + rn.getEndLine() + "\n" );
# finalResults.append("  end_column: " + rn.getEndColumn() + "\n");
# finalResults.append("  package: " + rn.getPackageName() + "\n" );
# finalResults.append("  class: " + rn.getClassName() + "\n" );
# finalResults.append("  rule_name: " + rn.getRule().getName() + "\n");
# finalResults.append("  rule_description: " + rn.getRule().getDescription().trim().replaceAll("\n", "<br/>" ).replaceAll(" ", "&nbsp;" ) + "\n" );
# finalResults.append("  example: " + rn.getRule().getExample().trim().replaceAll("\n", "<br/>" ).replaceAll(" ", "&nbsp;" ) + "\n" );
# finalResults.append("\n");
         
         count = count.next
       end
       
    end
  end
  
  ## Used for rendering the ant template
  class IoTemplate  
    attr_reader :compiler, :jvm, :base, :src, :build, :origional, :input, :output, :classname
    attr_writer :compiler, :jvm, :base, :src, :build, :origional, :input, :output, :classname
    
    def get_binding
      binding
    end
  end
  
  
  def run_io_check( queue, user_turnin, dir, directories, app )
    if user_turnin.assignment.auto_grade_setting.io_check?
      if ! user_turnin.safe_for_autograde?
        return "This turn-in set is not considered safe for automatic execution, an instructor needs to review the files first."
      end
      
      ## Cleanup previous
      IoCheckResult.delete_all( ["user_turnin_id = ?", user_turnin.id ] )
      
      puts("IO_C::#{queue.id} - START")
      
      sortable = Time.now.strftime("%Y%m%d")
      timestamp = Digest::SHA1.hexdigest( "grade key #{Time.now.to_formatted_s(:long)} #{queue.user_turnin.user.uniqueid}" )[0...10].upcase
      dest_dir = "#{app['temp_dir']}/autograde/#{queue.user_turnin.user.uniqueid}_#{sortable}_#{timestamp}/"
      
      puts("IO_C::#{queue.id} - TempDir=#{dest_dir}")
      
      ## Create dest dir
      `mkdir -p #{dest_dir}`
      puts("IO_C::#{queue.id} - Directory created")
      
      ## Create ANT file from template
      
      template = ""
      File.open( "#{ApplicationController.root_dir}/java/io_check_build.xml" ).each do |line|
        template = "#{template}#{line}"
      end
      #puts("IO_C::#{queue.id} - ANT Template:: \n #{template}")
      
      # set attributes
      vars = IoTemplate.new
      vars.compiler = app['javac']
      vars.jvm = app['java']
      vars.base = dest_dir
      vars.src = "#{dest_dir}src/"
      vars.build = "#{dest_dir}build/"
      vars.origional = "#{app['external_dir']}#{dir}"
      vars.input = "input_#{timestamp}.txt"
      vars.output = "output_#{timestamp}.txt"
      vars.classname = user_turnin.main_class
      
      rxml = ERB.new(template)
      rxml_result = rxml.result( vars.get_binding )
      ant_file = File.open("#{dest_dir}/build.xml", "w") 
      ant_file << rxml_result
      ant_file.close
      puts("IO_C::#{queue.id} - EXPANDED ANT FILE \n#{rxml_result}\nEND ANT FILE")
      
      ## Get the assignment
      assignment = user_turnin.assignment
      assignment.io_checks.each do |ioc|
        ## Write input file to disk
        input_file = File.open("#{dest_dir}#{vars.input}", 'w' )
        input_file << ioc.input
        input_file.close
        
        ## run the program
        ant_output = `#{app['ant']} -f #{dest_dir}/build.xml 2>&1`
        puts("IO_C::#{queue.id} - ANT Output:: \n #{ant_output}")
        
        if ant_output.index('BUILD SUCCESSFUL').nil?
          throw "Error during ANT script execution of your code: \n #{ant_output}"
        end

        if !ant_output.index('Timeout: killed the sub-process').nil?
          throw "Process killed - infinite loop is likely cause: \n #{ant_output}"
        end

        ## Read output from from disk
        user_output = ''
        File.open( "#{dest_dir}#{vars.output}" ).each do |line|
          ## Sometimes and puts a line int the file like
          ## Opening /tmp/autograde/helmicmt_20070115_F0D92E75C9/input_F0D92E75C9.txt
          if line.index("Opening #{dest_dir}#{vars.input}").nil?   
            user_output = "#{user_output}#{line}"
          end
        end
        
        puts("IOC_C::#{queue.id} - Program output\n#{user_output}")
        
        ## Create the iocheckresult
        io_result = IoCheckResult.new
        io_result.io_check_id = ioc.id
        io_result.user_id = user_turnin.user_id
        io_result.user_turnin_id = user_turnin.id
        io_result.output = user_output
        
        ## RUN THE DIFF - remove the trailling newline characters, avoid user confusion
        user_output = user_output.chomp while user_output[-1..-1].eql?("\n")
        compare_to = ioc.output
        compare_to = compare_to.chomp while compare_to[-1..-1].eql?("\n")
        
        puts("IOC_C::#{queue.id} - Starting DIFF")
        diffs = TextDiff.run_diff( compare_to, user_output )
        puts("IOC_C::#{queue.id} - DIFF Completed")
        max_match = ioc.output.length
        differences = 0
        diffs.each do |da|
          da.each do |change| 
            if change.action.eql?('+') || change.action.eql?('-') || change.action.eql?('!')
              differences += 1
            end
          end
        end
        differences = max_match if differences > max_match
        io_result.match_percent = sprintf("%.2f", (1.0 - differences.to_f / max_match) * 100).to_f
        puts("IO_C::#{queue.id} - Match Percent #{io_result.match_percent}%")
        
        io_result.diff_report = TextDiff.html_patch( ioc.output, diffs )
        puts("IO_C::#{queue.id} - Diff Report\n#{io_result.diff_report}")

        if ! io_result.save
          puts("IO_C::#{queue.id} - Error saving results.")
          
        end

        ## clean everything up      
        #`rm -r #{dest_dir}`
        puts("IO_C::#{queue.id} - Removed directory: #{dest_dir}")
      
      end
      
      puts("IO_C::#{queue.id} - END ")
    end
  end
  
  def git_clone_pull(queue, user_turnin, dir, directories, app)
    puts 'Performing a git clone/pull'
    queue.message = 'git pull has started.'
    
    if user_turnin.git_revision.nil?
      # Time to do a clone
      
    else
      # Time to do a pull
      
    end
    
    queue.message = 'git pull done.'
  end
  
    
  def execute()  
    puts "RUNNING WITH #{@gradeQueueId}"
    
    queue = GradeQueue.find(@gradeQueueId)  
    puts "Background grader started for request #{@gradeQueueId}"
    
    begin
    
      # This method is called in it's own new thread when you
      # call new worker. args is set to :args
      puts "Handling grading request number #{@gradeQueueId}"

      unless queue.acknowledged 
        queue.acknowledged = true
        queue.message = "Autograding has started."
        queue.save

        # user turnin - has the directory
        user_turnin = queue.user_turnin
        assignment = user_turnin.assignment 
        if assignment.team_project
          dir = user_turnin.get_team_dir( ApplicationController.external_dir, user_turnin.project_team )
        else
          dir = user_turnin.get_dir( ApplicationController.external_dir )
        end
        
        puts "Beginning grading on files in the directory = #{dir}"

        ## Set up direcories
        directories = Hash.new
        user_turnin.user_turnin_files.each do |utf|
          directories[utf.id] = utf if utf.directory_entry?
        end

        ## make sure that PMD is set up - but outside of a potentially long running transaction
        if user_turnin.assignment.auto_grade_setting.check_style?
          user_turnin.assignment.ensure_style_defaults # make sure that default settings exist
        end
 
        app = ApplicationController.app
        
        if user_turnin.assignment.use_github && !user_turnin.github_repository.nil?
          git_clone_pull(queue, user_turnin, dir, directories, app)
        end

        ## Just to have the status update outside of the transaction
        if user_turnin.assignment.auto_grade_setting.check_style?
          queue.message = "Performing static analysis on your code."
          queue.save
        end
        ##GradeQueue.transaction( queue, user_turnin ) do
          run_pmd( queue, user_turnin, dir, directories, app )
        ##end
        
        ## Again - to have status outside of transaction
        if user_turnin.assignment.auto_grade_setting.io_check?
          queue.message = "Compiling and running I/O based tests on your code."
          queue.save
        end
        ##GradeQueue.transaction( queue, user_turnin ) do
          run_io_check( queue, user_turnin, dir, directories, app )
        ##end

        queue.serviced = true
        queue.message = "AutoGrade complete."
        queue.save

        puts "Done with request #{@gradeQueueId}"
      else
        puts "Request #{@gradeQueueId} already acknowledged"
      end

    rescue ActiveRecord::StatementInvalid
        puts "MySQL is gone.."
        GradeQueue.connection.reconnect!
      unless queue.nil?
        queue.acknowledged = false
        queue.serviced=false
        queue.failed=false
        queue.message = "There was an error processing this submission. It is being retried."
        queue.save
      end

    
    rescue => doh
      puts "Request failed #{doh.message}"
      puts "#{doh.backtrace}" 
      unless queue.nil?
        queue.serviced=true
        queue.failed=true
        queue.message = doh.message
        queue.save
      end
    end
    
  end

end


if ARGV.size == 1
  job = AutogradeJob.new( ARGV[0].to_i )
  job.execute
  exit(0)
else
  puts "Incorrect number of arguments!"
  exit(1)
end
  

