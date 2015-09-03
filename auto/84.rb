class Protocol

  def debug
    true
  end

  def main

    o = op input

    o.input.all.take

    show do 
      title "Cut gel the"
    end

    o.output.all.produce
    o.input.all.release
    o.output.all.release

    return o.result

  end

end