class Protocol

  def f x
    x*x
  end

  def main

    (1..5).each do |i|

      j = f i

      data = show {
        title "Step #{i}" 
        note "#{i} squared is #{j}"
        get "number", var: "z#{i}", label: "Enter a number"
        select [ "A", "B" ], var: "x", label: "Choose something"
      }
      
      show {
        title "Results"
        note data.to_s
      }

    end

  end

end
