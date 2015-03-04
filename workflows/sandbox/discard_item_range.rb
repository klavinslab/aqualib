needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  def arguments
    {
      io_hash: {},
      lower_upper_bound: [9000,10000],
      sample_name: "Any",
      object_type_name: "TB Overnight of Plasmid",
      debug_mode: "Yes"
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

    io_hash[:item_ids] = *(io_hash[:lower_upper_bound][0]..io_hash[:lower_upper_bound][1])
  	items = []
    io_hash[:item_ids].each do |id| 
      item = find(:item, id: id)[0]
      if (item != nil)
        if (item.sample != nil)
          if (item.sample.name == io_hash[:sample_name] || io_hash[:sample_name].downcase == "any") && item.object_type.name == io_hash[:object_type_name]
            items.push item
          end
        end
      end
    end

  	take items, interactive: true, method: "boxes"
  	show {
  		title "Dispose or recycle depending on the items"
  		check "For glassware contained items, 50 mL Falcon tubes, 96 deepwell plates, take to the dishwashing station. For other items, discard properly to the bioharzard box."
  	}
  	items.each do |x|
  		x.mark_as_deleted
  		x.save
  	end
  	release items
    if io_hash[:task_ids]
      io_hash[:task_ids].each do |tid|
        task = find(:task, id: tid)[0]
        set_task_status(task,"discarded")
      end
    end
  end
end
