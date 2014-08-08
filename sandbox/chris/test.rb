class Protocol
  def main
    foo = find(:item, sample: { object_type: { name: "Enzyme Stocks" }, sample: { name: "Phusion HF Master Mix" } } )
    show {
      title "Hello World!"
      note "#{foo}"
    }
  end
end
