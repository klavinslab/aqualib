class Protocol

  def debug
    true
  end

  def main

    o = op input

    o.input.all.take

    o.output.all.produce

    t = Table.new(
      gel: "Gel id",
      row: "Row",
      col: "Lane"
      slice: "Gel Slice Id"
    )

    o.threads.each do |thread|
      t.gel(thread.input.gel.collection_id)
       .row(thread.input.gel.row)
       .col(thread.input.gel.col)
       .slice(thread.output.fragment.item_id)
       .append
    end

    show do
      title "Cut the gel slices and put them in new 1.5 uL tubes"
      table t.render
    end

    o.input.all.release
    o.output.all.release

    return o.result

  end

end