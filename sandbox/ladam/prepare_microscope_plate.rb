needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

#doc https://github.com/klavinslab/aquarium/blob/master/doc/Krill.md

class Protocol

    include Standard
    include Cloning

    def arguments
        {
          io_hash: {},
          overnight_id: 0,
          debug_mode: "No"
        }
    end

    def main

      io_hash = input[:io_hash]
      io_hash = input if !input[:io_hash] || input[:io_hash].empty?
      io_hash = { overnight_id: input[:overnight_id], debug_mode: input[:debug_mode] }.merge io_hash
      if io_hash[:debug_mode].downcase == "yes"
        def debug
          true
        end
      end


        overnight_id = io_hash[:overnight_ids][0]

        #use take items
        #take items, interactive: true

        #
        show {
            title "Prepare microscope plate"
            note "We will prepare the plate to be imaged."
        }


        #
        show {
            title "Centrifuge tube"
            check "Take the centrifuge tube #{overnight_id}_D from the shaker incubator."
            check "Centrifuge it for 5min at 3,000. Use the tube 1mL H2O next to the centrifuge to balance it."
            note "Go get next items in the meantime."
        }
        show {
            title "Get items"
            check "Clean you bench top. Use Kim wipes and ethanol spray."
            check "Find a plate in the fridge B13.120 labelled Microscope-YAPD. "
            note "It should have some little holes! If you can't find one, go get a new YAPD plate and name it \"Microscope-YAPD\"."
            check "Grab a new bottom glass mini plate from B9.500."
        }
        #
        show {
            title "Place cells"
            check "Return to the centrifuge and get #{overnight_id}_D."
            check "Remove 950uL of the supernatant from #{overnight_id}_D."
            check "Use the bench top vortexer to resuspend the cells in the tube."
            check "Take 1uL and put it onto the central disc of the microscope mini plate. "
            note "Make sure there is no bubbles."
            check "Grab a 1,000 uL pipette tip or two and use its larger opening to cut a patch from the YAPD plate, use second to drop it."
            check "Place patch onto the yeast cells (the drop) and press gently to spread the liquid."
            check "Put the lid back on the microscope plate and place it on a KIM wipe (for transport.)"
            image "press_agar_patch"
        }
        #
        show {
            title "Clean-up"
            note "Discard #{overnight_id}_D."
            check "Put the Microscope-YAPD plate with parafilm in the fridge B13.120."
            note "Get ready to take the microsopce plate to the microscope room."
        }
        if io_hash[:task_id]
            task = find(:task, id: io_hash[:task_id])[0]
            set_task_status(task,"microscope_plate_ready")
        end

        return { io_hash: io_hash }
    end
end
