needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  def move items, new_location
    # takes items (array or single objects) and move locations to new_location
    new_location = new_location.to_s
    items = [items] unless items.kind_of?(Array)
    items.each do |i|
      raise "Must be Item or Array of Items to move" unless i.class == Item
      i.location = new_location
      i.save
    end
  end # move

  def delete items
    # invoke mark_as_deleted for each item in items
    items = [items] unless items.kind_of?(Array)
    items.each do |i|
      raise "Must be Item or Array of Items to delete" unless i.class == Item
      i.mark_as_deleted
      i.save
    end
  end # delete

  def arguments
    {
      io_hash: {},
      ids: [3217],
      debug_mode: "Yes"
    }
  end

  def main
    io_hash = input[:io_hash]
    io_hash = input if !input[:io_hash] || input[:io_hash].empty?
    io_hash[:debug_mode] = input[:debug_mode] || "No"
    if io_hash[:debug_mode].downcase == "yes"
      def debug
        true
      end
    end
    # items = io_hash[:ids].collect {|id| find(:item, id:id)[0]}
    # take items, interactive: true
    # stripwells = produce spread items, "Stripwell", 1, 1
    # samples = items.collect { |i| i.sample }
    # show {
    #   title "Test page"
    #   note items.collect { |i| "#{i.class}"}
    #   note stripwells.collect { |s| "#{s.class}"+" #{s}"}
    #   note stripwells.collect { |s| "#{s}"}
    #   note items.collect { |i| "#{i}"}
    #   note samples.collect { |s| "#{s}"}
    # }
    # move items, "30 C incubator"
    # move items[0], "456 incuabtor"
    # # delete items
    # release items, interactive: true

    # gibson_info = gibson_assembly_status
    # ready_task_ids = gibson_info[:ready_ids]
    # ready_task_ids.each do |tid|
    #   ready_task = find(:task, id: tid)[0]
    #   group = Group.find_by_name("technicians")
    #   show {
    #     note "#{ready_task.task_prototype.name}"
    #     note "#{ready_task.user.login}"
    #     note "#{ready_task.user.member? group.id}"
    #     note "#{group}"
    #     if ready_task.user.member? group.id
    #       note "#{ready_task.user.login} is in group1"
    #     end
    #   }
    # end

    fragment = find(:sample,{ id: io_hash[:ids][0] })[0]
    props = fragment.properties
    template = props["Template"]
    template_items = template.in "1 ng/µL Plasmid Stock" if template.sample_type.name == "Plasmid"
    template_items = template.in "Gibson Reaction Result"
    show {
      title "Test"
      note "#{template_items[0]}"
    }


  end # main
end # Protocol
