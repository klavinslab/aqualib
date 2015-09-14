class Protocol

  def main
 
    result = show {
      title "Hello Bootcamp!"
      note "Seriously? 9-1 every day this week??"
      table [["A","B"],[1,2]]
      check "Check this"
      select [ "A", "B", "C" ], var: "x", label: "Choose something", default: 1
    }
    
    show do
      title "You entered #{result[:x]}"
    end
    
    return { x: x, y: "that was fun" }
  
  end
  
end
