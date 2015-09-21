class Protocol

  def main
    o = op input

    o.input.all.take
    o.output.all.produce
    
    show {
      title "LB Liquid Media"
      note "Description: This prepares a bottle of LB Media for growing bacteria"
      note "Total duration: 3 hours"
      note "Total worktime: 30 minutes"
      warning "To add antibotics, wait for contents to cool to 40 C and add the appropriate amount of antibiotics"
    }

    show {
      title "Place large weigh boat on gram scale and zero"
    }
    
    show {
      title "Measure out 20 grams of LB media powder and pour contents into liter bottle"
      }
      
    show {
      title "Measure out 800 mL of DI water using the graduated cyinder and pour into liter bottle"
    }
    
    show {
      title "Close liter bottle and shake until all contents are solvated"
    }
    
    o.input.all.release
    o.output.all.release

    return o.result

  
  end
  
end
