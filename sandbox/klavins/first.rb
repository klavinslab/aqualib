class Protocol

  def debug
    true
  end

  def arguments
    { message: "Please Provide a Title" }
  end

  def main

    msg = input[:message]

    x = show {
      title msg
      image "gel_in_solution"
      note "Thanks for using aquarium :-)"
      warning "Careful!"
      check "Check me"
      select [ "A", "B", "C" ], var: "x", label: "Choose something", default: 1
      get "text", var: "y", label: "Enter a string", default: "Hello World"
      get "number", var: "z", label: "Enter a number", default: 555
    }
    
    responses = (x.reject { |k,v| k == :timestamp }).collect { |k,v| "#{k}: #{v}" }

    show {
      title "Thanks"
      note "You entered:"
      responses.each do |n|
        note n
      end
    }

  end

end
