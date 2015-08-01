
class Protocol

  def debug
    true
  end

  def main

    o = op input

    o.input.all.take {
      note "Take all the items"
    }

    show {
      title "#{o.name} Inputs"
      note "Detailed instructions go here"
    }

  end

end
