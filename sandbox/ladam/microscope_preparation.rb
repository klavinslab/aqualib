needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

    include Standard
    include Cloning

    def arguments
        {
          io_hash: {},
          debug_mode: "No"
        }
    end

    def main
      io_hash = input[:io_hash]
      io_hash = input if !input[:io_hash] || input[:io_hash].empty?
      io_hash = { debug_mode: input[:debug_mode] }.merge io_hash
      if io_hash[:debug_mode].downcase == "yes"
        def debug
          true
        end
      end


        #
        show {
            title "Prepare the microscope for use"
            note "This protocol outlines the procedures for safe setup of the microscope. Adhering to this protocol may save you thousands in damage costs!"
            note "Go to the microscope room and resume the protocol from there. If already in the microscope room click next."

        }


        show {
            title"Setting up the microscope for use"
            note "In the next few steps we will set up the microscope to track cells for our timelapse microscopy."
            warning "THIS EQUIPMENT IS EXTREMELY EXPENSIVE! UTMOST CARE MUST BE USED WHEN HANDING THE MICROSCOPE"
            warning "THE STEPS SHOULD BE FOLLOWED TO THE LETTER, ELSE YOU MAY BE FINED WITH HEAVY REPLACEMENT COSTS"
            image "microscope"
        }

        show {
            title "Turn on the fluorescent light bulb"
            check "Labeled '1' and must be turned on first because it draws an extremely high current."
            warning "FAILURE TO DO THIS FIRST MAY RESULT IN A BROKEN SYSTEM."
            image "fluorescent lamp label 1"
        }

        show {
            title "Turn on the shutter controller"
            check "Labeled 2, must be turned on second. The switch is in the back"
            image "shutter controller label 2"
            note "Center the shutter controller:"
            check "Flip the tuner switch up and down TWICE, and verifies it aligned in the middle ('Auto' position). This will reset the controller fully"
        }

        show {
            title "Turn on the microscope bright-light controller"
            note "Labeled 3 and must be turned on third"
            image "lamp controller label 3"
        }

        show {
            title "Turn on the microscope"
            check "Labeled number 4. The switch is a little difficult to find so you may need to feel around for it."
            image "micrscope label 4"
        }

        show {
            title "Turn on the microscope light"
            check "Labeled 5 and produces the light from the mechanism above the incubator"
            note "The button is on the left side. "
            note "Make sure the knob 'Port' side to eye, located on the opposite side, is switch on side (computer)."
            image "microscope light label 5"
        }

        show {
            title "Turn on the X-Y controller"
            check "Labeled 6 and helps us pan through the surface to find cells at a fixed focal point z"
            image "xy_controller_label 6"
        }

        show {
            title "Turn on the fine Z tunning controller"
            check "Labeled 7 and adjusts our focal points when searching for cells"
            note "The switch is on the left side of the controller"
            note "Remember that if the z controller does not work, it might be that the sliding element on the bottom left side of the microscope is on the microscope position only. You need to slide it to the middle, then Z can be controlled from bot the Z controller or the microscope knob (bottom right)."
            image "z_focus_label 7"
        }

        show {
          title "Turn on the microscope incubator"
          check "Turn on the incubator for the microscope labeled 0."
          note "It should be set to 30 degrees celsius for yeast cells (37 for E.coli)"
          image "incubator_controller"
        }

        show {
          title "Finished!"
          note "It takes about 30min to heat up to 30C."
        }


        if io_hash[:task_id]
            task = find(:task, id: io_hash[:task_id])[0]
            set_task_status(task,"microscope_ready")
        end

        return { io_hash: io_hash }

    end
end
