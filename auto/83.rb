class Protocol

  def debug
    true
  end

  def main

    o = op input

    o.input.all.take

    # load the gel with ladder
    o.input.gel.collections.each do |gel| 
      gel.set 0, 0, o.input.ladder.instances.first[:item]
    end

    # load the fragments

    show do 
      title "Run the gel"
    end

    o.output.all.release

    return o.result

  end

end