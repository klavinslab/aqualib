class Protocol

  def main

    o = op input

    o.input.all.take
    o.output.all.produce

    show {
      title "Autoclave: stick autoclave tape on top of bottle cap, loosen top and autoclave at 110C for 15 minutes."
      timer initial: { hours: 0, minutes: 15, seconds: 0}
    }
    
    show {
      title "Remove from Autoclave: put on thermal gloves and take bottle out of autoclave, place on stir plate."
      warning "Stuff caked at the bottom: after autoclaving, there is stuff caked at the bottom, do not use this batch, shake harder in step 5, make sure that everything is solvated before autoclaving"
    }
    
    show {
      title "Stir: Heat to 65C while stirring at 700 rpm."
    }

    o.input.all.release
    o.output.all.release

    return o.result

  end

end
