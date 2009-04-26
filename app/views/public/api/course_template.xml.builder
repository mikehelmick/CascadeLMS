xml.instruct!
xml.course_template do
  xml.title "#{@course_template.title}"
  xml.start_date "#{@course_template.start_date}"
  xml.outcomes do
    parent_stack = [-1]
    count_stack = [0]
    @course_template.ordered_outcomes.each do |outcome|
      if outcome.parent == parent_stack[-1] ## Same level %>
        count_stack.push( count_stack.pop + 1 ) 
      elsif parent_stack.index( outcome.parent ).nil?  ## New level %>
        parent_stack.push outcome.parent 
        count_stack.push 1
      else ## need to pop back to correct level %>
        while (parent_stack[-1] != outcome.parent) 
          parent_stack.pop
          count_stack.pop
        end 
        count_stack.push( count_stack.pop + 1 )
      end 

      xml.outcome do
        xml.number "#{count_stack.join('.')}"
        xml.title "#{outcome.outcome}"
        
        xml.mappings do
          @course_template.programs.each do |program|
            xml.program do
              xml.title "#{program.title}"
              count = 0
              xml.program_outcomes do
                program.program_outcomes.each do |prog_outcome|
                  count = count.next
                  if outcome.mapped_to_program_outcome?(prog_outcome.id)
                    xml.program_outcome "#{count}) #{prog_outcome.outcome}"
                  end
                end
              end
            end
          end
        end
        
      end
    end  
  end
  
end