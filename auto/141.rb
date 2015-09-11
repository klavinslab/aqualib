class Protocol

  def debug
    true
  end

  def main

    o = op input

    show do
      o.threads.each do |thread|
        note "Buy primer #{thread.input.primer.sample}"
      end
    end

    return o.result

  end

end
