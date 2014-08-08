class Protocol

  def debug
  	true
  end

  def main

    show({title: "Click OK to generate an error"})

    1/0

  end

end
