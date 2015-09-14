class Protocol

  def main
  
    result = show {
      title "Test"
      note "dage"
      table [["A","B"],[1,2]]
      check "Check"
      select [ "A", "B", "C" ], var: "choice", label: "Choose something", default: 1
    }
    
    x = result[:choice]
    
    return { x: x, y: "that was fun" }
  
  end
  
end
