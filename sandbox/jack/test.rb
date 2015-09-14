class Protocol

  def main
  
    show {
      title "This is cool!"
      note "What am I doing"
      table[["A","C"], [1,3]]
      check "Check this!"
      select["E","F"], var:"x", label: "Select an option"
    }
    
    show do
     title "You entered #{result[:x]}"
    end
    
    return {x:x, y:"That was fun"}
  end
  
end
