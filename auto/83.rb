class Protocol

  def debug
    true
  end

  def main

    o = op input

    o.input.all.take

    # load the gel with ladder
    o.input.gel.collections.each do |gel|
      gel.set 0, 0, o.input.ladder.sample_ids.first
      gel.set 1, 0, o.input.ladder.sample_ids.first
    end

    # load the fragments
    o.threads.spread(gels,non_empty: true) do |thread, slot| 
      thread.output.fragment.associate slot
    end

    show do 
      title "Run the gel"
    end

    o.output.all.release

    return o.result

  end

end