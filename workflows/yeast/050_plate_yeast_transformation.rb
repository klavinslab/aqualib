needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  def arguments
    {
      io_hash: {},
      yeast_transformation_mixture_ids: [12293],
      debug_mode: "Yes"
    }
  end
  
  def main
    io_hash = input[:io_hash]
    io_hash = input if input[:io_hash].empty?
    if io_hash[:debug_mode].downcase == "yes"
      def debug
        true
      end
    end

    yeast_transformation_mixtures = io_hash[:yeast_transformation_mixture_ids].collect {|tid| find(:item, id: tid )[0]}
    take yeast_transformation_mixtures, interactive: true
    
    show {
      title "Resuspend in water"
      check "Spin down all the tubes in a small table top centrifuge for ~1 minute"
      check "Pipette off supernatant being careful not to disturb yeast pellet"
      check "Add 600 µL of sterile water to each eppendorf tube"
      check "Resuspend the pellet by vortexing the tube throughly"
      warning "Make sure the pellet is resuspended and there are no cells stuck to the bottom of the tube"
    }

    yeast_plates = yeast_transformation_mixtures.collect {|y| produce new_sample y.sample.name, of: "Yeast Strain", as: "Yeast Plate"}

    move yeast_plates, "30 C incubator"

    tab = [["Yeast Transformation Mixtures id","Plate id"]]
    yeast_transformation_mixtures.each_with_index do |y,idx|
      tab.push([y.id,yeast_plates[idx].id])
    end

    show {
      title "Plating"
      check "Grab #{yeast_plates.length} +G418 plates. Label plates with the following ids"
      note (yeast_plates.collect{|y| "#{y}"})
      check "Flip the plate and add 4-5 glass beads to it"
      check "Add 200 µL of the transformation mixture from the tube according to the following table"
      table [["Yeast Transformation Mixtures id","Plate id"]].concat(yeast_transformation_mixtures.collect { |y| y.id }.zip yeast_plates.collect { |y| { content: y.id, check: true } })
    }

    show {
      title "Shake and incubate"
      check "Shake the plates in all directions to evenly spread the culture over its surface till dry"
      check "Discard the beads in a used beads container"
      check "Throw away transformation mixture tubes"
      check "Put the plates with the agar side up in the 30C incubator"
    }
    
    release yeast_plates, interactive: true
    delete yeast_transformation_mixtures

    if io_hash[:task_ids]
      io_hash[:task_ids].each do |tid|
        task = find(:task, id: tid)[0]
        set_task_status(task,"plated")
      end
    end
    io_hash[:plate_ids] = [] if !io_hash[:plate_ids]
    io_hash[:plate_ids].concat yeast_plates.collect { |p| p.id }
    
    return { io_hash: io_hash }
  end # main
  
end # Protocol
