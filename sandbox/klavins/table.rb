class Protocol

  def main

    m = [
      [ "An", "Absolutely", "Wonderful", { content: "Table", style: { color: "#f00" } } ],
      [ { content: 1, check: true }, 2, 3, 4 ]
    ]

    show {
             title "A Table"
             table m
    }

  end

end
