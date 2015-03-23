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

  def primer_ordering_status p={}
    params = ({ group: false }).merge p
    tasks_all = find(:task,{task_prototype: { name: "Primer Order" }})
    tasks = []
    # filter out tasks based on group input
    if params[:group]
      user_group = params[:group] == "technicians"? "cloning": params[:group]
      group_info = Group.find_by_name(user_group)
      tasks_all.each do |t|
        tasks.push t if t.user.member? group_info.id
      end
    else
      tasks = tasks_all
    end
    waiting = tasks.select { |t| t.status == "waiting" }
    ready = tasks.select { |t| t.status == "ready" }

    # cycling through waiting and ready to make sure primer info are in place

    (waiting + ready).each do |t|

      t[:primers] = { ready: [], no_sequence_info: [] }

      t.simple_spec[:primer_ids].each do |prid|
        primer = find(:sample, id: prid)[0]
        seq = (primer.properties["Overhang Sequence"] || "") + (primer.properties["Anneal Sequence"] || "")
        if seq.length > 0
          t[:primers][:ready].push prid
        else
          t[:primers][:no_sequence_info].push prid
        end
      end

      if t[:primers][:ready].length == t.simple_spec[:primer_ids].length
        t.status = "ready"
        t.save
      else
        t.status = "waiting"
        t.save
      end
    end

    return {
      waiting_ids: (tasks.select { |t| t.status == "waiting" }).collect {|t| t.id},
      ready_ids: (tasks.select { |t| t.status == "ready" }).collect {|t| t.id}
    }
  end ### primer_ordering_status

  def main
    io_hash = input[:io_hash]
    io_hash = input if !input[:io_hash] || input[:io_hash].empty?
    if io_hash[:debug_mode].downcase == "yes"
      def debug
        true
      end
    end
    io_hash = { primer_ids: [] }.merge io_hash

    primer_orders = primer_ordering_status

    io_hash[:task_ids] = primer_orders[:ready_ids]

    io_hash[:task_ids].each do |tid|
      ready_task = find(:task, id: tid)[0]
      io_hash[:primer_ids].concat ready_task.simple_spec[:primer_ids]
    end

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

