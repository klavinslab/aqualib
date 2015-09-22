class Protocol

  def main
    o = op input

    o.input.all.take
    o.output.all.produce

# is there fridge in workflow?
    show {
      title "Place plates in 30C incubator for 12 hours"
      timer initial: {12 hours: 0, minutes: 0, seconds: 0}
    }
    
    show {
      title "Retrieve plates from 30C incubator and back into sleeves"
    }
    
    show {
      title "Store at 4C in the deli fridge"
    }
    
    o.input.all.release
    o.output.all.release

    return o.result

  
  end
  
end
