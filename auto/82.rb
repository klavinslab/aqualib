
class Protocol
  
  def main

    o = op input

    o.input.all.take

    show {
      title "#{o.name} Inputs"
      note "Detailed instructions go here"
    }

    o.output.all.produce
    
    o.input.all.release
    o.output.all.release

    return o.result     

  end

end
