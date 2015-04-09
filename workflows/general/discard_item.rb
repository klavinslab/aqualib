needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  def arguments
    {
      io_hash: {},
      "item_ids Yeast Plates" => [1234],
      task_ids: [2310, 2309],
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
        task.save
      end
    end
  end
end
