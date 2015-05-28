needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  def arguments
    {
      io_hash: {},
      object_type_name: "Yeast Plate",
      debug_mode: "No"
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

    all_items = find(:item, object_type: { name: io_hash[:object_type_name] })
    items = []
    all_items.each do |i|
      if i.id < 30000  && i.sample.in("Yeast Glycerol Stock").length > 0
        items.push i
      end
    end

  	take items, interactive: true, method: "boxes"

    items.each do |p|
      tp = TaskPrototype.where("name = 'Discard Item'")[0]
      t = Task.new(
          name: "#{p.sample.name}_plate_#{p.id}",
          specification: { "item_ids Yeast Plate" => [p.id] }.to_json,
          task_prototype_id: tp.id,
          status: "waiting",
          user_id: p.sample.user.id)
      t.save
      t.notify "Automatically created from clean up protocol.", job_id: jid
    end
  	# show {
  	# 	title "Dispose or recycle depending on the items"
  	# 	check "For glassware contained items, 50 mL Falcon tubes, 96 deepwell plates, take to the dishwashing station. For other items, discard properly to the bioharzard box."
  	# }
  	# items.each do |x|
  	# 	x.mark_as_deleted
  	# 	x.save
  	# end
  	# release items
    # if io_hash[:task_ids]
    #   io_hash[:task_ids].each do |tid|
    #     task = find(:task, id: tid)[0]
    #     set_task_status(task,"discarded")
    #   end
    # end
  end
end
