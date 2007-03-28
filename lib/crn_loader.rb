## This is for Miami - this will pre-load CRNs for course information
## You may want to do something like this for your school

require 'net/http'
require 'uri'

class CrnLoader
  
  @@campus = [" 'O' "," 'H' "," 'M' "]

  def initialize( term_string, subjects )
    @term = term_string
    @subjects = subjects
  end

  def load
    result = 'Result of CRN import:<br/>'

    subjects = @subjects.split(" ")
    # [ "CSA","MTH","MIS", "IMS" ]
    
    @@campus.each do |campus|

      subjects.each do |subject|

      # Post a form to the courselist app
      # <hack>will dump all courses for a department in a term</hack>
      res = Net::HTTP.post_form(URI.parse('http://www.admin.muohio.edu/cfapps/courselist/selection_display.cfm'),
                                    {'term'=>@term, 
                                     'campus'=> campus,
                                     'subj'=>subject,
                                     'course_type'=>'',
                                     'part_term'=>'',
                                     'level'=>'',

                                     'course' => '',
                                     'crn' => '',
                                     'title' => '',
                                     'search_text' => '',
                                     'begin_time' => '',
                                     'end_time' => '',
                                     'submit' => 'Get Classes',

                                     'campus_required' => 'A Campus must be selected',
                                     'subj_required' => 'A Subject must be selected'
                                     })
      #puts res.body
      base_crn = @term

      step = 0
      crn = ''
      subj = ''
      number = ''
      section = ''
      title = ''

      res.body.each_line do |line|

            case step
              when 0
                unless line.index('<A HREF="http://www.ucm.muohio.edu/').nil?
                  crn = line[line.index('>')+1...line.rindex('<')].strip
                  step = 1
                end
              when 1
                unless line.index('</TD>').nil?
                  step = 2
                end
              when 2
                unless line.index('</TD>').nil?
                  subj = line[0...line.index('&nbsp;')].strip
                  step = 3
                end
              when 3
                unless line.index('</TD>').nil?
                  number = line[0...line.index('&nbsp;')].strip
                  step = 4
                end
              when 4
                unless line.index('</TD>').nil?
                  section = line[0...line.index('&nbsp;')].strip
                  step = 5
                end
              when 5
                unless line.index('</TD>').nil?
                  step = 6
                end  
              when 6
                unless line.index('</TD>').nil?
                  title = line[0...line.index('&nbsp;')].strip
                  step = 0

                  result = "#{result}#{base_crn}#{crn} #{subj}#{number}-#{section} #{title}   ...   "

                  new_crn = Crn.new
                  new_crn.crn = "#{base_crn}#{crn}"
                  new_crn.name = "#{subj}#{number}-#{section}"
                  new_crn.title = title
                  #puts "#{new_crn.inspect}"
                  if new_crn.save
                    result = "#{result} CREATED <br/>\n"
                  else
                    result = "#{result} FAILED <br/>\n"
                  end

                  crn = ''
                  subj = ''
                  number = ''
                  section = ''
                  title = ''
                end
            end

          end

        end
      end
      return result
    end

end