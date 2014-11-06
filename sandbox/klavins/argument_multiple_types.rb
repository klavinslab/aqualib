class Protocol

  def arguments
    {
      "ids Fragment|Plasmid" => [0]
    }
  end

  def main

    samples = input[:ids].collect { |i| find(:sample,id:i)[0] }

    show {
      title "Samples input"
      samples.each { |s|
        note "name: #{s.name}, type: #{s.sample_type.name}"
      }
    }

  end

end