needs "aqualib/lib/standard"
class Protocol

  include Standard

  def arguments
    {
      io_hash: {},
      gel_ids: [35130],
      gel_band_verify: "Yes",
      plate_ids: [35290,35291,35292,35293],
      debug_mode: "No"
    }
  end

  def gel_band_verify col, options = {}
    m = col.matrix
    routes = []
    opts = { except: [], plate_ids: [] }.merge options
    opts[:plate_ids].uniq!

    (0..m.length-1).each do |i|
      (0..m[i].length-1).each do |j|
        if m[i][j] > 0 && ! ( opts[:except].include? [i,j] )
          s = find(:sample,{ id: m[i][j] })[0]
          length = 0
          if s.description
            description = s.description
            description = " " if description.empty?
            length = description.split('QC_length')[-1].split(':')[-1].to_i
          end
          length = 'N/A' if length == 0
          routes.push lane: [i,j], length: length
        end
      end
    end

    verify_data = show {
      title "Verify that each lane matches expected size"
      note "Select No if there is no band or band does not match expected size,
      select N/A if expected length is N/A and there is a band."
      routes.each_with_index do |r,idx|
        select ["N/A", "Yes", "No"], var: "verify#{r[:lane][0]}_#{r[:lane][1]}", label: "Does gel lane on Row #{r[:lane][0]+1} Col #{r[:lane][1]+1} match the expected length of #{r[:length]} bp"
      end
    }

    if opts[:plate_ids].length > 0
      plates = opts[:plate_ids].collect { |id| find(:item, id: id)[0] }
      take plates
      (0..m.length-1).each do |i|
        (0..m[i].length-1).each do |j|
          if m[i][j] > 0 && ! ( opts[:except].include? [i,j] )
            s = find(:sample,{ id: m[i][j] })[0]
            plate = (plates.select { |p| p.sample.name == s.name })[0]
            result = plate.datum[:QC_result]
            if result
              result.push verify_data[:"verify#{i}_#{j}".to_sym]
            else
              result = [verify_data[:"verify#{i}_#{j}".to_sym]]
            end
            plate.datum = plate.datum.merge({ QC_result: result })
            plate.save
          end
        end
      end
      plates.each do |plate|
        qc_result = plate.datum[:QC_result] || []
        correct_colony_result = qc_result.each_index.select{ |i| qc_result[i] == "Yes" }
        correct_colony_result.map! { |x| x+1 }
        plate.datum = plate.datum.merge({ correct_colony: correct_colony_result })
        plate.save
      end
      release plates
    end

  end #gel_band_verify

  def main
    io_hash = input[:io_hash]
    io_hash = input if input[:io_hash].empty?
    io_hash = { debug_mode: "No", gel_band_verify: "No", yeast_plate_ids: [] }.merge io_hash
  	gels = io_hash[:gel_ids].collect { |i| collection_from i }
    # re define the debug function based on the debug_mode input
    if io_hash[:debug_mode].downcase == "yes"
      def debug
        true
      end
    end
    take gels, interactive: true
  	gels.each do |gel|
  		show {
  			title "Image gel #{gel.id}"
  			check "Clean the transilluminator with ethanol."
  			check "Put the gel #{gel.id} on the transilluminator."
  			check "Put the camera hood on, turn on the transilluminator and take a picture using the camera control interface on computer."
  			note "Rename the picture you just took as gel_#{gel.id}. Upload it!"
  			upload var: "my_gel_pic"
  		}
      if io_hash[:gel_band_verify].downcase == "yes"
        gel_band_verify gel, except: [ [0,0], [1,0] ], plate_ids: io_hash[:yeast_plate_ids]
      end
  	end

    if io_hash[:gel_band_verify].downcase == "yes"
      plates = io_hash[:yeast_plate_ids].collect { |id| find(:item, id: id)[0] }
      plates.each do |p|
        if p.datum[:correct_colony]
          if p.datum[:correct_colony].length > 0
            tp = TaskPrototype.where("name = 'Glycerol Stock'")[0]
            t = Task.new(
                name: "#{p.sample.name}_plate_#{p.id}",
                specification: { "item_ids Yeast Plate" => [p.id] }.to_json,
                task_prototype_id: tp.id,
                status: "waiting",
                user_id: p.sample.user.id)
            t.save
            t.notify "Automatically created from Yeast Strain QC.", job_id: jid
          end
        end
      end
    end

    if io_hash[:task_ids]
      io_hash[:task_ids].each do |tid|
        task = find(:task, id:tid)[0]
        set_task_status(task,"gel imaged")
      end
    end

  	release gels, interactive: true
    return { io_hash: io_hash }
  end # main

end
