class Protocol

  def main
    o = op input

    o.input.all.take
    o.output.all.produce

    show {
      title "LB Agar"
      note "Description: This protocol is for the preperation of LB Agar, the common plate media for growing bacteria cells."
      note "Total duration: 3 hours"
      note "Total worktime: 30 minutes"
      warning "Wait until the agar has cooled enough to touch with bare hands and add the appropriate amount of antibiotic while stirring"
    }
    
    show {
      title "Get Bottle and Stir Bar: Retrieve one Glass Liter Bottle from the glassware rack and one Medium Magnetic Stir Bar from the dishwashing station, bring to weigh station. Put the stir bar in the bottle."
    }
    
    show {
      title "Weigh Agar: Using the gram scale, large weigh boat, and chemical spatula, weigh out 29.6 grams of LB Agar powder and pour into the bottle."
      }
      
    show {
      title "Using the graduated cylinder measure out 800 mL of DI water."
    }
    
    show {
      title "Measure out Water: fill bottle with DI water, shake to get all powder solvated."
    }
    
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
