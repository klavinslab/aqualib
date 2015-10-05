class Protocol
  
  def main
    o = op input
    
    o.input.all.take
    o.output.all.produce
    
    show {
      title "Make YPAD Media"
      note "Description: Make 800 mL of yeast extract-peptone-dextrose medium + adenine (YPAD)"
    }
    
    show {
      note "Label the empty 1000 mL bottle"
    }
    
    show {
      note "Weight out yeast extract, peptone, dextrose, and adenine sulfate (and optional agar) and add to 1000 mL bottle"
    }
    
    show {
      note "Add 500 mL dIH2O to bottle, close cap tightly and shake to mix"
    }
    
    show {
      note "Add water to 800 mL mark on bottle, shake again to mix"
    }
    
    show {
      note "Place cap on bottle loosely"
    }
    
    show {
      note "Stick autoclave tape on the cap"
    }
    
    show {
      note "Autoclave 15 minutes at 110°C, minimal drying cycle (optional cycle)."
    }
    
    
    o.input.all.release
    o.output.all.release

    return o.result

  
  end
  
end
