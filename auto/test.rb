
class Protocol

  def debug
    true
  end

  def main

    o = op input

    o.input.all.mtake

    show {
      title "#{o.name} Inputs"
      note "Detailed instructions go here"
    }

  end

end
