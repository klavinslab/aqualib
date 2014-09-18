class Protocol
  def main
    all_plasmids = find(:item, sample: { object_type: { name: "Plasmid Stock" } })
    plasmids_1_6 = all_plasmids[0..5]

    #empty_collection = produce new_collection, "Gel", 2, 6
    #filled_collection = collection_from plasmids_1_6

    filled_collection = produce spread plasmids_1_6, "Gel", 2, 6
    show {
      note plasmids_1_6
    }
  end
end
