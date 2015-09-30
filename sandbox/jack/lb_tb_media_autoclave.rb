class Protocol

  def main

    o = op input

    o.input.all.take
    o.output.all.produce

    show {
      title "Autoclave for Bacteria"
      note "Description: This protocol is for sterilizing the media used for bacteria"
      warning "Wait until the agar has cooled enough to touch with bare hands and add the appropriate amount of antibiotic while stirring"
    }
    
    show {
      note "Stick autoclave tape on top of the bottle"
    }
    
    show {
      note "Loosen cap and autoclave at 110C for 15 minutes"
      note "Click next to start timer"
    }
    
    show {
      timer initial: { hours: 0, minutes: 15, seconds: 0}
    }
    
    show {
      warning "Stuff caked at the bottom: after autoclaving, if there is stuff caked at the bottom, do not use this batch, remake the media and make sure that everything is solvated before autoclaving (shake harder)"
    }

    o.input.all.release
    o.output.all.release

    return o.result

  end

end
