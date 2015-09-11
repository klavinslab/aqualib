class Protocol

  def main

    o = op input

    o.input.all.take
    o.output.all.produce

    show do
      title "Instructions here"
    end

    o.input.all.release
    o.output.all.release

    return o.result

  end

end