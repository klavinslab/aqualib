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
      title "Get Bottle and Stir Bar"
      note "Retrieve one Glass Liter Bottle from the glassware rack and one Medium Magnetic Stir Bar from the dishwashing station, bring to weigh station. Put the stir bar in the bottle."
    }
    
    show {
      title "Weigh Agar"
      note "Using the gram scale, large weigh boat, and chemical spatula, weigh out 29.6 grams of LB Agar powder and pour into the bottle."
      }
      
    show {
      title "Measure Water"
      note "Using the graduated cylinder measure out 800 mL of DI water."
    }
    
    show {
      title "Mix solution"
      note "fill bottle with DI water, shake to get all powder solvated."
    }
    
    o.input.all.release
    o.output.all.release

    return o.result

  
  end
  
end
