class Protocol
  def main
    m = [["A", "Very", "Nice", {content: "Table", style: { color: "#f00" }}],
         [{content: 1, check: true}, 2, 3, 4]]
    show {
      table m
    }
  end
end
