class Protocol

  def debug
    true
  end

  def main

    o = op input

    o.input.all.take

    # load the gel with ladder
    o.input.gel.collections.each do |gel|
      puts "putting ladder in gel #{gel.inspect}"
      gel.set 0, 0, o.input.ladder.instances.first[:item]
      gel.set 1, 0, o.input.ladder.instances.first[:item]      
      puts "matrix is now #{gel.matrix}"
    end

    # load the fragments

    show do 
      title "Run the gel"
    end

    o.output.all.release

    return o.result

  end

end