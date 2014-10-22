class Protocol


  def main

    u = show {
      title "Enter a value"
      get "text", var: "y", label: "Enter a string", default: "Hello World"
    }

    return {
      number: 0,
      str: u[:y]
    }

  end