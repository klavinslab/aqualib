class Protocol

  def main
    o = op input

    o.input.all.take
    o.output.all.produce

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
    
    show {
      title "Stick autoclave tape on top of the bottle"
    }
    
    show {
      title "Loosen cap and autoclave at 110C for 15 minutes"
      timer initial: { hours: 0, minutes: 15, seconds: 0}
    }
    

    o.input.all.release
    o.output.all.release

    return o.result

  
  end
  
end
