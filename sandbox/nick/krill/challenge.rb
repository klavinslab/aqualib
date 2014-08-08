class Protocol
  def main
    all_plasmids = find(:item, object_type: { name: "Plasmid Stocks" })
    plasmids_1_6 = all_plasmids[0..5]
    show {
      note plasmids_1_6
    }
  end
end
