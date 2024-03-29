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

    show {
      title "Prepare to order primer"
      check "Go to the <a href='https://www.idtdna.com/site/account' target='_blank'>IDT website</a>, log in with the lab account. (Username: UW_BIOFAB, password is the lab general password)."
      warning "Ensure that you are logged in to this exact username and password!"
    }

    tab = [[]]
    primers.each_with_index do |primer, idx|
      tab.push [primer.id.to_s + " " + primer.name, primer.properties["Overhang Sequence"] + primer.properties["Anneal Sequence"]]
    end
    primer_lengths = primers.map { |p| (p.properties["Overhang Sequence"] + p.properties["Anneal Sequence"]).length }
    primers_over_60 = primers.select.with_index { |p, idx| primer_lengths[idx] > 60 && primer_lengths[idx] <= 90 }.map { |p| "#{p} (##{primers.index(p) + 1})" }.join(", ")
    primers_over_90 = primers.select.with_index { |p, idx| primer_lengths[idx] > 90 }.map { |p| "#{p} (##{primers.index(p) + 1})" }.join(", ")
    idt = show {
      title "Create an IDT DNA oligos order"
      warning "Oligo concentration for primer(s) #{primers_over_60} will have to be set to \"100 nmole DNA oligo.\"" if primers_over_60 != ""
      warning "Oligo concentration for primer(s) #{primers_over_90} will have to be set to \"250 nmole DNA oligo.\"" if primers_over_90 != ""
      check "Click Custom DNA Oligos, click Bulk Input. Copy paste the following table and then click the Update button."
      table tab
      check "Click Add to Order, review the shopping cart to double check that you entered correctly. There should be #{primers.length} primers in the cart."
      check "Click Checkout, then click Continue."
      check "Enter the payment information, click the oligo card tab, select the Card1 in Choose Payment and then click Submit Order."
      check "Go back to the main page, let it sit for 5-10 minutes, return and refresh, and find the order number for the order you just placed."
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
