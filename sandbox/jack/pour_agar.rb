class Protocol

  def main
    o = op input

    o.input.all.take
    o.output.all.produce

  # total duration incorrect if splitting up into two days
    show {
      title "Pouring Agar"
      note "Description: This protocol describes the steps needed to generate plate media from liquid state agar"
      note "Total duration: 12 hours"
      note "Total worktime: 20 minutes"
      warning "Pour Ring Malformed: Sometimes the pour ring is malformed, making pouring difficult, obatain a good pour ring that is sterile and replace the one on the bottle"
    }
    
    show {
      title "Open both sleeves of plastic petri dishes by tearing plastic sleeve open at the indicated position, invert the stack and pull on the bag to empty the contents"
    }
    
    show {
      title "Open agar bottle and one petri dish, pour agar until roughly 75% of the plate surface is covered"
    }
    
    show {
      title "In one quick swirling motion, cover the rest of the petri dish surface with agar and replace lid"
    }
    
    show {
      title "Repeat until all plates are poured"
    }
    
    show {
      title "Wait until plates are solidified"
    } 
  
    
    o.input.all.release
    o.output.all.release

    return o.result

  
  end
  
end
