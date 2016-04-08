needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  def arguments
    {
      io_hash: {},
      "item_ids Yeast Plates" => [62211, 55615, 59943],
      task_ids: [],
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
  	items = io_hash[:item_ids].collect { |id| find(:item, id: id)[0] }
    items = items.compact
    items = items.sort_by { |i| i.location }
    r = Regexp.new ( '(M20|M80|SF[0-9]*)\.[0-9]+\.[0-9]+\.[0-9]+' )
    items_for_box = items.select { |i| r.match(i.location) }
  	take items_for_box, interactive: true, method: "boxes"
    items_for_table = items - items_for_box
    items_table = [["Item id", "Container Type", "Location"]]
    items_for_table.each do |i|
      items_table.push ["#{i}", "#{i.object_type.name}", { content: "#{i.location}", check: true }]
    end
    show {
      title "Gather the following item(s)"
      table items_table
    }
  	show {
  		title "Dispose or recycle depending on the items"
  		check "For glassware contained items, 50 mL Falcon tubes, 96 deepwell plates, take to the dishwashing station. For other items, discard properly to the bioharzard box."
  	}
  	items.each do |x|
  		x.mark_as_deleted
  		x.save
  	end unless io_hash[:debug_mode].downcase == "yes"
  	release items
    if io_hash[:task_ids]
      io_hash[:task_ids].each do |tid|
        task = find(:task, id: tid)[0]
        set_task_status(task,"discarded")
        task.save
      end
    end
  end
end
