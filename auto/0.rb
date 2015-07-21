class Protocol

  def debug
    true
  end

  def main

    data = input

    show do 
      title "Generic Protocol"
      note data.to_json
    end

    return { todo: "make new items" }

  end

end