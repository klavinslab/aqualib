
class Protocol

  def debug
    true
  end

  def main

    o = op input

    o.input.all.take {
      note "Take all the inputs."
    }

    show {
      title "#{o.name} Inputs"
      note "Detailed instructions go here"
    }

    o.output.all.produce

    o.input.all.release {
      note "Release all the inputs."
    }    

    o.putput.all.release {
      note "Release all the outputs."
    }        

  end

end
