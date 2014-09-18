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
    item = choose_sample "phi29 DNA Polymerase", quantity: 1

    # choose multiple item from sample name
    items = choose_sample "Phusion HF Master Mix", quantity: 3

    take [item] + items, interactive: true

    # choose a single item from object name
    item = choose_object "1 L Bottle", quantity: 1, take: true

    # choose multiple item from object name
    items = choose_object "500 mL Bottle", quantity: 3, take: true

    release [item] + items


  end

end