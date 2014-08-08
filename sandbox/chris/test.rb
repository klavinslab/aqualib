class Protocol
  def main
    foo = find(:item, sample: { object_type: { name: "Enzyme Stock" }, sample: { name: "Phusion HF Master Mix" } } )
    l = foo.length
    xx = 3
    show {
      title "Hello World!"
      note "#{l} xx: #{xx}"
    }
  end
end
