class Protocol

  def main

    frag = find(:sample,sample_type: {name: 'Fragment'}).last

    items = [
      produce(frag.make_item "Fragment Stock"),
      produce(new_sample "pLAB1", of: "Plasmid", as: "Plasmid Stock")
    ]

    items.each { |i| i.reload }

    ids = items.collect { |item| item.id }

    show {
      title "Produced #{items.length} New Items"
      table [ ids ]
    }

    found = ids.collect { |id| f = find(:item,{id: id})[0] }

    show {
      title "Found #{found.length} Items"
      table [ found.collect { |item| item.id } ]
    }

    release items

    return { found: ids }

  end

end