needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  def arguments
    {
      io_hash: {},
      yeast_transformation_mixture_ids: [13574,13575,25701,27087,34086,34087,27089],
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

    yeast_transformation_mixtures = io_hash[:yeast_transformation_mixture_ids].collect { |tid| find(:item, id: tid )[0] }
    yeast_plates = yeast_transformation_mixtures.collect {|y| produce new_sample y.sample.name, of: "Yeast Strain", as: "Yeast Plate"}

    if yeast_transformation_mixtures.length == 0
      show {
        title "No plating required"
        note "No transformed aliquots need to be plated. Thanks for your effort!"
      }
    else

      take yeast_transformation_mixtures, interactive: true

      num = yeast_transformation_mixtures.length

      show {
        title "Transfer into 1.5 mL tube"
        check "Take #{num} 1.5 mL tube, label with #{io_hash[:yeast_transformation_mixture_ids]}."
        check "Transfer contents from 14 mL tube to each same id 1.5 mL tube."
        check "Recycle or discard all the 14 mL tubes."
      }
      
      show {
        title "Resuspend in water"
        check "Spin down all 1.5 mL tubes in a small table top centrifuge for ~1 minute"
        check "Pipette off supernatant being careful not to disturb yeast pellet"
        check "Add 600 µL of sterile water to each eppendorf tube"
        check "Resuspend the pellet by vortexing the tube throughly"
        warning "Make sure the pellet is resuspended and there are no cells stuck to the bottom of the tube"
      }

      yeast_markers = yeast_plates.collect {|y| y.sample.properties["Integrant"].properties["Yeast Marker"].downcase[0,3].to_sym}
      yeast_plates_markers = Hash.new {|h,k| h[k] = [] }
      yeast_plates.each_with_index do |y,idx|
        yeast_markers.uniq.each do |mk|
          yeast_plates_markers[mk].push y if yeast_markers[idx] == mk
        end
      end

      antibiotic_hash = { nat: "+ClonNat", kan: "+G418", hyg: "+Hygromycin", ble: "+BleoMX", his: "-HIS" }

      tab_plate = [["Plate Type","Quantity","Id to label"]]
      yeast_plates_markers.each do |marker, plates|
        tab_plate.push( [ antibiotic_hash[marker], plates.length, plates.collect { |y| y.id }.join(", ") ])
      end

      tab = [["Yeast Transformation Mixtures id","Plate id"]]
      yeast_transformation_mixtures.each_with_index do |y,idx|
        tab.push([y.id,yeast_plates[idx].id])
      end

      show {
        title "Plating"
        check "Grab plates and label."
        table tab_plate
        check "Flip the plate and add 4-5 glass beads to it"  
        check "Add 200 µL of 1.5 mL tube contents according to the following table"
        table [["1.5 mL tube id","Plate id"]].concat(yeast_transformation_mixtures.collect { |y| y.id }.zip yeast_plates.collect { |y| { content: y.id, check: true } })
      }

      show {
        title "Shake and incubate"
        check "Shake the plates in all directions to evenly spread the culture over its surface till dry"
        check "Discard the beads in a used beads container."
        check "Throw away all 1.5 mL tubes."
        check "Put the plates with the agar side up in the 30C incubator."
      }

      move yeast_plates, "30 C incubator"
      release yeast_plates, interactive: true
      #delete yeast_transformation_mixtures
    end

    io_hash = ({ plate_ids: [], task_ids: [] }).merge io_hash
    io_hash[:task_ids].each do |tid|
      task = find(:task, id: tid)[0]
      set_task_status(task,"plated")
    end
    io_hash[:plate_ids].concat yeast_plates.collect { |p| p.id }
    
    return { io_hash: io_hash }
  end # main
  
end # Protocol
