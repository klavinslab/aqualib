class Protocol

  def main
 
    result = show {
      title "Hello World!"
      note "What is this."
      table [["A","B"],[1,2]]
      check "Check this"
      select [ "A", "B", "C" ], var: "x", label: "Choose one", default: 1
    }
    
    show do
      title "You entered #{result[:x]}"
    end
    
    return { x: result[:x], y: "that was fun" }
  
  end
  
end
