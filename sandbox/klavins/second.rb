class Protocol

  def f x
    x*x
  end

  def main

    (1..5).each do |i|

      show(
        { title: "Step #{i}" }, 
        { note: "#{i} squared is #{f i}" },
        { input: { type: "number", var: "z#{i}", label: "Enter a number" } },
        { select: { choices: [ "A", "B" ], var: "x", label: "Choose something" } }
      )

    end

  end

end
