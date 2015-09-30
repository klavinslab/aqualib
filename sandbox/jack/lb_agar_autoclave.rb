class Protocol

  def main

    o = op input

    o.input.all.take
    o.output.all.produce

    show {
      note "Autoclave: stick autoclave tape on top of bottle cap, loosen top and autoclave at 110C for 15 minutes."
      timer initial: { hours: 0, minutes: 15, seconds: 0}
    }
    
    show {
      note "Remove from Autoclave: put on thermal gloves and take bottle out of autoclave, place on stir plate."
      warning "Stuff caked at the bottom: after autoclaving, if there is stuff caked at the bottom, do not use this batch, remake the media and make sure that everything is solvated before autoclaving (shake harder)"
    }
    
    show {
      note "Stir: Heat to 65C while stirring at 700 rpm."
    }

    o.input.all.release
    o.output.all.release

    return o.result

  end

end
