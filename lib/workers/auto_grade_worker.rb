require 'application'

# Put your code that runs your task inside the do_work method it will be
# run automatically in a thread. You have access to all of your rails
# models.  You also get logger and results method inside of this class
# by default.
class AutoGradeWorker < BackgrounDRb::Worker::RailsBase
  
  def do_work(args)
    queue = GradeQueue.find(args.to_i)
    begin
    
    # This method is called in it's own new thread when you
    # call new worker. args is set to :args
    logger.info("Handling grading request number #{args.to_i}")
    
    
    unless queue.acknowledged 
      queue.acknowledged = true
      queue.save
    
      # user turnin - has the directory
      user_turnin = queue.user_turnin
      dir = user_turnin.get_dir( ApplicationController.external_dir )
    
      logger.info("Beginning grading on files in the directory = #{dir}")
     
      ## Set up direcories
      directories = Hash.new
      user_turnin.user_turnin_files.each do |utf|
        directories[utf.id] = utf if utf.directory_entry?
      end
      
      app = ApplicationController.app
      if user_turnin.assignment.auto_grade_setting.check_style?
         jars = "#{ApplicationController.root_dir}/java/#{app['pmd_libs'].join(":#{ApplicationController.root_dir}/java/")}"
         command = "#{app['java']} -cp #{jars} #{app['pmd_main']} "
         
         # get files and delete old results
         files = Array.new
         user_turnin.user_turnin_files.each do |utf|
           if utf.filename.reverse[0..4].eql?('avaj.')
             files << "#{dir}#{utf.full_filename(directories)}"
             FileStyle.delete_all( "user_turnin_file_id = #{utf.id}")
           end
         end
         
         command = "#{command} #{files.join(' ')}"
         logger.info("SHELL: #{command}")
         result = `#{command}`
        
         #### Parse results
         yaml_res = YAML.load( result )
         
         # get the PMD settings
         user_turnin.assignment.ensure_style_defaults # make sure that default settings exist
         checks = Hash.new
         filter = Hash.new
         user_turnin.assignment.assignment_pmd_settings.each do |pmd|
           if !pmd.enabled
             filter[pmd.style_check.name] = true
           end
           checks[pmd.style_check.name] = pmd.style_check
         end
          
         count = 0
         ## ERROR ON THIS LINE
         while !yaml_res["violation#{count}"].nil?
           summary = yaml_res["violation#{count}"]
           
           filename = summary['filename']
           user_turnin.user_turnin_files.each do |utf|
             if filename.eql?( "#{dir}#{utf.full_filename(directories)}" )
               logger.info( "(#{count}) #{summary['rule_name']} in file #{filename}")
               
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
      
    
      queue.serviced = true
      queue.save
    
      logger.info("Done with request #{args.to_i}")
    else
      logger.info("Request #{args.to_i} already acknowledged")
    end
    
    
    rescue => doh
      logger.error("Request failed #{doh.message}")
      unless queue.nil?
        queue.serviced=true
        queue.failed=true
        queue.message = doh.message
        quque.save
      end
    end
      results[:do_work_time] = Time.now.to_s
      results[:done_with_do_work] = true
      delete
  end

end
AutoGradeWorker.register
