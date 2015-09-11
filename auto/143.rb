class Protocol

  def debug
    true
  end

  def main

    o = op input

    o.output.all.produce

    show do
      o.threads.each do |thread|
        title "make aliquot #{thread.output.aliquot.item_id} and #{thread.output.stock.item_id} "
      end
    end

    o.output.all.release

    return o.result

  end

end
