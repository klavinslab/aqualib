class Protocol

  def main

    o = op input

    o.input.all.take
    o.output.all.produce

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
