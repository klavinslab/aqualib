needs "aqualib/lib/standard"

class Protocol

  include Standard

  def arguments

    {
      "ids Fragment" => [0]
    }

  end

  def main

    choose_sample "Phusion HF Master Mix", quantity: 3

  end

end