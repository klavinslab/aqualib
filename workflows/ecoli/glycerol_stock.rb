needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  def arguments
    {
      io_hash: {},
      "overnight_ids TB Overnight of Plasmid" =>[67889, 47558],
      debug_mode: "yes"
    }
  end

  def main
    io_hash = input[:io_hash]
    io_hash = input if !input[:io_hash] || input[:io_hash].empty?
    io_hash = { debug_mode: "No", overnight_ids: [], glycerol_stock_ids:[], yeast_plate_task_ids:[] }.merge io_hash
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
      glycerol = find(:item, { object_type: { name: "50 percent Glycerol (sterile)" }, location: "Bench"})[0]
      take [glycerol], interactive: true

       glycerol_stock_table = [["Item Number", "Strain ID", "Strain Name"]]

      # produce glycerol_stocks and set up datum to track which overnights it made from
      glycerol_stocks = overnights.collect { |y| produce new_sample y.sample.name, of: y.sample.sample_type.name, as: name_glycerol_hash[y.sample.sample_type.name] }
      glycerol_stocks.each_with_index do |x,idx|
        x.datum = { from: overnights[idx].id }
        x.save
      end

      #adds relevant information to the glycerol stock table 
      glycerol_stocks.each do |y|
        glycerol_stock_table.push ["#{y.id}","#{y.sample.id}", "#{y.sample.name}"]
      end

      #show the user steps for using label printer 
      show{
        title "Print out labels"
        note "On the computer near the label printer, open Excel document titled 'Glycerol stock label template'." 
        note "Copy and paste the table below to the document and save."
        table glycerol_stock_table
        note "Ensure that the correct label type is loaded in the printer: B33-181-492 should show up on the display. 
          If not, get help from a lab manager to load the correct label type."
        note "Open the LabelMark 6 software and select 'Open' --> 'File' --> 'Glycerol stocks.l6f'"
        note "A window should pop up. Under  'Start' enter #{glycerol_stocks[0].id} and set 'Total' to #{overnights.length}. Select 'Finish.'"
        note "Click on the number in the top row of the horizontal side label and select 'Edit External Data'. A window should pop up. Select 'Finish'."
        note "Select 'File' --> 'Print' and set the printer to 'BBP33'."
        note "Collect labels."
      }



      # show the user steps to prepare glycerol stocks
      show {
        title "Prepare glycerol in cryo tubes."
        check "Take #{overnights.length} Cryo #{"tube".pluralize(overnights.length)}"
        check "Label each tube with the printed out labels"
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
            specification: { "item_ids Item" => [p.id] }.to_json,
            task_prototype_id: tp.id,
            status: "waiting",
            user_id: p.sample.user.id,
            budget_id: 1)
        t.save
        t.notify "Automatically created after glycerol stock made.", job_id: jid
      end
      glycerol_stocks.each_with_index do |glycerol_stock, idx|
        if glycerol_stock.object_type.name == "Yeast Glycerol Stock"
          if io_hash[:yeast_plate_task_ids].length > 0
            yeast_plate_task_id = io_hash[:yeast_plate_task_ids][idx]
            budget_id = find(:task, id: yeast_plate_task_id)[0].budget_id
          else
            budget_id = 1
          end
          new_tasks = create_new_tasks(glycerol_stock.id, task_name: "Streak Plate", user_id: glycerol_stock.sample.user.id, budget_id: budget_id)
          new_tasks[:new_task_ids].each do |tid|
            t = find(:task, id: tid)[0]
            t.notify "Automatically created after glycerol stock made.", job_id: jid
          end
        end
      end
    end
    io_hash[:glycerol_stock_ids] = io_hash[:glycerol_stock_ids].concat glycerol_stocks.collect { |g| g.id }
    return { io_hash: io_hash }
  end # main

end # protocol
