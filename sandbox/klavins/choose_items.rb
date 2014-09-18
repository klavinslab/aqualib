needs "aqualib/lib/standard"

class Protocol

  include Standard

  def arguments

    {
      "ids Yeast Overnight Suspension" => [0]
    }

  end

  def main

    item = choose_sample "Phusion HF Master Mix", quantity: 1

    release [ item ]

  end

end