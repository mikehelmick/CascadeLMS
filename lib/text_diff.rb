
require 'rubygems'
require 'diff/lcs'
require 'diff/lcs/hunk'

class TextDiff
  
  def TextDiff.process_spaces( output ) 
    return "&nbsp;" if output.eql?(" ") 
    
    html = ""
     0.upto(output.size-1) do |i|
      str = output[i...i+1]
      if str.eql?(" ") && output[i-1...i].eql?(" ")
        html << "&nbsp;"
      else 
        html << str
      end
    end
    return html
  end
  
  def TextDiff.html_patch(src, patchset )
    patch_map = {
      :patch => { '+' => '+', '-' => '-', '!' => '!', '=' => '=' },
      :unpatch => { '+' => '-', '-' => '+', '!' => '!', '=' => '=' }
    }


    string = src.kind_of?(String)
      # Start with a new empty type of the source's class
    res = src.class.new

      # Normalize the patchset.
    patchset = Diff::LCS.__normalize_patchset(patchset)

    direction = :patch

    ai = bj = 0

    patchset.each do |change|
        # Both Change and ContextChange support #action
      action = patch_map[direction][change.action]

      case change
      when Diff::LCS::ContextChange
        case direction
        when :patch
          el = change.new_element
          old = change.old_element
          op = change.old_position
          np = change.new_position
        when :unpatch
          el = change.old_element
          op = change.new_position
          np = change.old_position
        end

        case action
        when '-' # Remove details from the old string
          while ai < op
            res << (string ? src[ai, 1] : src[ai])
            ai += 1
            bj += 1
          end

          res << "<span class=\"diffSub\">#{TextDiff.process_spaces(old)}</span>"

          ai += 1
        when '+'
          while bj < np
            res << (string ? src[ai, 1] : src[ai])
            ai += 1
            bj += 1
          end

          res << "<span class=\"diffAdd\">#{TextDiff.process_spaces(el)}</span>"
          bj += 1
        when '='
            # This only appears in sdiff output with the SDiff callback.
            # Therefore, we only need to worry about dealing with a single
            # element.
          res << el

          ai += 1
          bj += 1
        when '!'
          while ai < op
            res << (string ? src[ai, 1] : src[ai])
            ai += 1
            bj += 1
          end

          bj += 1
          ai += 1

          res << "<span class=\"diffChange\">#{TextDiff.process_spaces(el)}</span>"
        end
      when Diff::LCS::Change
        case action
        when '-'
          while ai < change.position
            res << (string ? src[ai, 1] : src[ai])
            ai += 1
            bj += 1
          end
          ai += 1
        when '+'
          while bj < change.position
            res << (string ? src[ai, 1] : src[ai])
            ai += 1
            bj += 1
          end

          bj += 1

          res << change.element
        end
      end
    end

    while ai < src.size
      res << (string ? src[ai, 1] : src[ai])
      ai += 1
      bj += 1
    end

    res
  end


  def TextDiff.run_diff( data_old, data_new )
    Diff::LCS.sdiff( data_old, data_new, Diff::LCS::ContextDiffCallbacks)
  end
  
  def TextDiff.run_html_diff()
    diffs = Diff::LCS.sdiff( data_old, data_new, Diff::LCS::ContextDiffCallbacks)
    TextDiff.html_patch( data_old, diffs ).gsub(/\n/, '<br/>')
  end
  
end