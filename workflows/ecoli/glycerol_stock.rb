needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  def arguments
    {
      io_hash: {},
      "overnight_ids TB Overnight of Plasmid" =>[],
      debug_mode: "No"
    }
  end

  def main
    io_hash = input[:io_hash]
    io_hash = input if !input[:io_hash] || input[:io_hash].empty?
    io_hash = { debug_mode: "No", overnight_ids: [], glycerol_stock_ids:[] }.merge io_hash
    if io_hash[:debug_mode].downcase == "yes"
      def debug
        true
      end
    end
    glycerol_stocks = []
    if io_hash[:overnight_ids].empty?
      show {
        title "No glycerol stocks need to be made"
        note "No glycerol stocks need to be made, thanks for your effort!"
      }
    else
      overnights = io_hash[:overnight_ids].collect {|id| find(:item, id: id )[0]}
      take overnights, interactive: true
      name_glycerol_hash = { "Plasmid" => "Plasmid Glycerol Stock", "Yeast Strain" => "Yeast Glycerol Stock", "E coli strain" => "E coli Glycerol Stock" }
      glycerol = choose_object "50 percent Glycerol (sterile)", take: true

      # produce glycerol_stocks and set up datum to track which overnights it made from
      glycerol_stocks = overnights.collect { |y| produce new_sample y.sample.name, of: y.sample.sample_type.name, as: name_glycerol_hash[y.sample.sample_type.name] }
      glycerol_stocks.each_with_index do |x,idx|
        x.datum = { from: overnights[idx].id }
        x.save
      end

      # show the user steps to prepare glycerol stocks
      show {
        title "Prepare glycerol in cryo tubes."
        check "Take #{overnights.length} Cryo #{"tube".pluralize(overnights.length)}"
        check "Label each tube with #{(glycerol_stocks.collect {|y| y.id}).join(", ")}"
        check "Pipette 900 µL of 50 percent Glycerol into each tube."
        warning "Make sure not to touch the inner side of the Glycerol bottle with the pipetter."
      }

      # Add overnights to cyro tubes
      show {
        title "Add overnight suspensions to Cyro tube"
        check "Pipette 900 µL of overnight suspension (vortex before pipetting) into a Cyro tube according to the following table."
        table [["Overnight id","Cryo tube id"]].concat(overnights.collect { |o| o.id }.zip glycerol_stocks.collect { |g| { content: g.id, check: true } })
        check "Cap the Cryo tube and then vortex on a table top vortexer for about 20 seconds"
        check "Discard the used overnight suspensions."
      }

      # Discard the overnights
      show {
        title "Discard overnights"
        check "Discard the used overnight suspensions. For glass tubes, place in the washing station. For plastic tubes, press the cap to seal and throw into biohazard boxes."
      }
      delete overnights
      release [glycerol], interactive: true
      release glycerol_stocks, interactive: true, method: "boxes"
    end
    if io_hash[:task_ids]
      io_hash[:task_ids].each do |tid|
        task = find(:task, id: tid)[0]
        set_task_status(task,"done")
      end
    end
    if io_hash[:item_ids] && io_hash[:old_overnight_ids]
      io_hash[:item_ids].each do |id|
        p = find(:item, id: id)[0]
        tp = TaskPrototype.where("name = 'Discard Item'")[0]
        t = Task.new(
            name: "#{p.sample.name}_plate_#{p.id}",
            specification: { "item_ids Yeast Plate" => [p.id] }.to_json,
            task_prototype_id: tp.id,
            status: "waiting",
            user_id: p.sample.user.id)
        t.save
        t.notify "Automatically created after glycerol stock made.", job_id: jid
      end
    end
    io_hash[:glycerol_stock_ids] = io_hash[:glycerol_stock_ids].concat glycerol_stocks.collect { |g| g.id }
    return { io_hash: io_hash }
  end # main

end # protocol
