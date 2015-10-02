class Protocol

  def main

    o = op input

    o.input.all.take
    o.output.all.produce
    
    show {
      note "Stir: Heat to 65C while stirring at 700 rpm."
    }

    o.input.all.release
    o.output.all.release

    return o.result

  end

end
