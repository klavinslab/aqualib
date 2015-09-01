class Protocol

  def debug
    true
  end

  def main

    o = op input

    show do 
      title "Generic Protocol"
    end

    return o.result

  end

end