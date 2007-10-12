## utility class that looks for differences in files of a certain extension
## from a base directory and takes in a threshold for differences
class DiffCount
  
  def DiffCount.assignment_diff( diff_cmd, wc_cmd, files, diff_count = 25 )
    differences = Array.new
    
    key_arr = files.keys
    
    0.upto( key_arr.size - 1 ) do |i|
      (i+1).upto( key_arr.size - 1 ) do |j|
      
        puts "#{diff_cmd} #{files[key_arr[i]]} #{files[key_arr[j]]} | #{wc_cmd} -l"
      
        lines = `#{diff_cmd} #{files[key_arr[i]]} #{files[key_arr[j]]} | #{wc_cmd} -l`
      
        puts "------\n#{lines}\n-----"
      
        begin
          if ( lines.to_i <= diff_count )
            smalldiff = Array.new
            smalldiff << lines.to_i
            smalldiff << key_arr[i]
            smalldiff << key_arr[j]
            
            differences << smalldiff
          end
        rescue Exception => e
        end
        
      end
    end
    
    return differences
  end
  
end