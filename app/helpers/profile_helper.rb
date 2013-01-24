module ProfileHelper

  def majors_array(majors)
    return "[\"#{majors.join('", "')}\"]"
  end
end
