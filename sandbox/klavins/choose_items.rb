needs "aqualib/lib/standard"

class Protocol

  include Standard

  def arguments

    {
      "ids Yeast Overnight Suspension" => [0]
    }

  end

  def main

    # choose a single item from sample name
    poly = choose_sample "phi29 DNA Polymerase", quantity: 1

    # choose multiple item from sample name
    mixes = choose_sample "Phusion HF Master Mix", quantity: 3

    take [poly] + mixes, interactive: true

    # choose a single item from object name
    bottle = choose_object "1 L Bottle", quantity: 1, take: true

    # choose multiple item from object name
    bottles = choose_object "500 mL Bottle", quantity: 3, take: true

    release [ poly, bottle ] + mixes + bottles

  end

end