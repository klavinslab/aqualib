class Protocol

  def main

    o = op input

    o.input.all.take
    o.output.all.produce
    
    type = o.input.all.samples
    label = type.gsub(/(unsterile)/,'')
    
    if (type.include? "LB" || type.include? "TB")
      temp = 121
    elsif(type.include? "SDO" || type.include? "SC")
      temp = 110
    else 
      raise ArgumentError, 'Parameter is not valid'
    end
      
    show {
      title "Autoclave Media"
      note "Description: This protocol is for sterilizing the media used for #{label}"
    }
    
    show {
      title "Tape Bottle"
      note "Stick autoclave tape on top of the bottle"
      warning "Make sure that the tape seals the cap to the bottle so that when you open the bottle you have to break the tape"
    }
    
    show {
      title "Autoclave"
      note "Check the water levels in the autoclave"
      note "Loosen cap and autoclave at #{temp}C for 15 minutes"
      note "5 beeps will signify that the autoclave is done"
    }

    o.input.all.release
    o.output.all.release

    return o.result

  end

end
