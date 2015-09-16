class Protocol

  def main
  
    result = show do
      title "Hello Bootcamp!"
      note "Seriously? 9-1 for real???"
      table [["A", "2"],[3,4]]
      check "Please check this. (please!)"
      select ["C","D"], var: "choice", label: "Do the thing", default: 1
    end
    
    x = result[:choice]
    
    show {
      title "Here There is a Title. Also, you entered #{x}."
    }
    
    return { x: x, y: "that was fun" }
    
  end
end
