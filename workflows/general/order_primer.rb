needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

# protocol for ordering primers

class Protocol

  include Standard
  include Cloning

  def arguments
    {
      io_hash: {},
      "primer_ids Primer" => [3967,3966],
      debug_mode: "Yes",
      group: "cloning"
    }
  end

  def main
    io_hash = input[:io_hash]
    io_hash = input if !input[:io_hash] || input[:io_hash].empty?
    if io_hash[:debug_mode].downcase == "yes"
      def debug
        true
      end
    end
    io_hash = { primer_ids: [] }.merge io_hash

    io_hash[:primer_ids].uniq!

    primers = io_hash[:primer_ids].collect { |x| find(:sample, id: x)[0] }

    tab = [[]]
    primers.each do |primer|
      tab.push [primer.id.to_s + " " + primer.name, primer.properties["Overhang Sequence"] + primer.properties["Anneal Sequence"]]
    end

    idt = show {
      title "Create an IDT DNA oligos order"
      check "Go to the IDT website idtdna.com/UWBIOCHEMSTORES/, log in with the lab account. (Username: mnparks@uw.edu, password is the lab general password)."
      check "Click Custom DNA Oligos, click Bulk Input. Copy paste the following table and then click the Update button."
      table tab
      check "Click Add to Order, review the shopping cart to double check that you entered correctly. There should be #{primers.length} primers in the cart."
      check "Click Checkout, then click Continue, and then click Submit."
      check "Go back to the main page, find the order number for the order you just placed, enter in the following."
      get "text", var: "order_number", label: "Enter the IDT order number below", default: 100
    }

    io_hash[:order_number] = idt[:order_number]

    if io_hash[:task_ids]
      io_hash[:task_ids].each do |tid|
        task = find(:task, id: tid)[0]
        set_task_status(task,"ordered")
      end
    end

    return { io_hash: io_hash }

  end

end
