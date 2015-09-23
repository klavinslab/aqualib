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

        show {
          title "Setup the microscope lens"
          note "In this protocol we will set up the microscope lens."
          warning "Please read the instructions VERY carefully before actually performing them. The microscope is expensive!!"
        }

        show {
          title "Clean the lens"
          warning "DO NOT USE A KIM WIPE FOR THIS, YOU MAY DAMAGE THE LENS"
          note "The lens is located within the center of the incubation chamber"
          check "Using an Olympus lens cleaner located near the microscope clean the objective lens"
          note "Rub gently in a circle on the lens to ensure proper cleaning"
          image "lens_cleaner_wipe"
        }

        show {
          title "Oil the lens"
          note "The oil is located inside and on the right of the incubator."
          check "Open the oil bottle intake some oil into the dropper"
          note "Use the opening of the bottle to remove excess oil from the dropper"
          check "Place one drop of oil directly in the center of the objective lens"
          check "Recap the oil bottle and put it back inside the incubation chamber"
          image "oil"
        }


        show {
          title "Cover plate in clear plastic wrap"
          check "Remove the lid. Leave plate on KIM wipe."
          check "Tear an ample section of plastic wrap to cover the plate."
          note "The film should be placed smoothly on the opening such that no wrinkles show. There should be enough plastic wrap to completely cover the sides."
          check "Cut excess film. No film must be on the bottom."
          check "Place lid back on."
          image "dish_with_plastic_wrap"
        }


        show {
          title "Place dish on the lens stage"
          warning "Be careful not to touch the dish to the objective lens, it may ruin the experiment"
          check "Lower stage if necessary using the large knob on the right hand side of the microscope"
          check "Make sure you have the mount to put the plate else use the screw driver and change it."
          check "Fix the plate to the extreme left of the mount and make sure it holds firmly in place."
          warning "If the dish moves finding cells may be impossible, and may also damage the lens."
          image "place_plate_microscope"
        }

        show {
          title "Adjust the objective lens"
          warning "THIS IS IMPORTANT IF THIS ISN'T DONE YOU MAY GET NO RESULTS"
          check "Center the dish using the X-Y controller so the agar center is at the center of the lens focal point"
          note "Locate the stage knob near the bottom right side of the eye piece"
          note "This is the LARGER of the two knobs"
          check "Adjust the objective lens toward the agar dish, just until the oil begins to spread on the bottom of the dish"
          warning "If the oil spreads too much this protocol must be restarted. If the oil doesn't spread at all you may not see any cells."
          image "Big knob"
        }

        show {
          title "Finalize the bright-light fixture"
          note "Locate the brightlight fixture above the incubation chamber"
          check "Flip it down and set fixture to phase 3 THIS MUST BE VERIFIED????!!!!!"
          check "Lower the light fixture so that the light shines on the objective lens"
          image "dish setup"
        }

        show {
          title "Setup complete!"
          note "We are now ready to search for cells on the computer, click next to procede to the next protocol"
        }

        if io_hash[:task_id]
            task = find(:task, id: io_hash[:task_id])[0]
            set_task_status(task,"microscope_lens_ready")
        end

        return { io_hash: io_hash }

    end
end
