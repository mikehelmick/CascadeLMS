## This is for Miami - this will pre-load CRNs for course information
## You may want to do something like this for your school

## Modified June 1, 2007 - Miami Output format changed
## 

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
                  from = line.index('<A HREF="http://www.ucm.muohio.edu/') + 1
                  crn = line[line.index('>', from )+1...line.index('<', from )].strip
                  
                  step = 1
                end
              when 1
                unless line.index('class="colCrse"').nil?
                  from = line.index('class="colCrse"')
                  
                  subjNum = line[line.index('>', from )+1...line.index('</td', from )].strip
                  subjNumArr = subjNum.split('&nbsp;') 
                  
                  subj = subjNumArr[0]
                  number = subjNumArr[1].to_i
                  
                  step = 4
                end
              when 4
                unless line.index('class="colSeq"').nil?
                  from = line.index('class="colSeq"')
                  
                  section = line[line.index('>', from )+1...line.index('</td', from )].strip
                 
                  step = 6
                end
              when 6
                unless line.index('class="colTitle"').nil?
                  from = line.index('class="colTitle"') rescue from = 0
                  title = line[line.index('>', from )+1...line.index('</td', from )].strip
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

