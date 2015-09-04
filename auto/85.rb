class Protocol

  def debug
    true
  end

  def main

    o = op input

    o.input.all.take
    o.output.all.produce

    ingredients = Table.new(
      slice: "Gel slice id",
      stock: "Fragment stock id"
    )

    o.threads.each do |thread|
      ingredients
        .slice(thread.input.fragment.item_id)
        .stock(thread.output.fragment.item_id)
        .append
    end

    show do
      title "Purify the gel slices and put the results in the 1.5 uL tubes"
      table ingredients.all.render
    end

    o.input.all.release
    o.output.all.release

    return o.result

  end

end