class Protocol

  def main

    o = op input

    o.input.all.take
    o.output.all.produce

    show {
      title "LB Agar"
      note "Description: This protocol is for the preperation of LB Agar, the common plate media for growing bacteria cells."
      warning "Wait until the agar has cooled enough to touch with bare hands and add the appropriate amount of antibiotic while stirring"
    }
    
    show {
      note "Autoclave: stick autoclave tape on top of bottle cap, loosen top and autoclave at 110C for 15 minutes."
      timer initial: { hours: 0, minutes: 15, seconds: 0}
    }
    
    show {
      note "Remove from Autoclave: put on thermal gloves and take bottle out of autoclave, place on stir plate."
    }
    
    show {
      note "Stir: Heat to 65C while stirring at 700 rpm."
    }

    o.input.all.release
    o.output.all.release

    return o.result

  end

end
