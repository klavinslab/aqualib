needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

#doc https://github.com/klavinslab/aquarium/blob/master/doc/Krill.md

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


        #use take items
        #take items, interactive: true

        #
        show {
            title "Stop Stofware"
            note "Go back to the microscope room. Make sure the experiment is finished, that the file is saved. Upload it."
            upload var: "nd_file"
            note "Quit NIS Element."
        }

        #
        show {
            title "Turn off microscope"
            note "Lower the Z to minimum."
            note "Remove the microscope plate."
            note "Turn off, in reverse order, all the components of the microscope. Finish by 1."
            note "Leave the room and discard the microscope plate in the wet lab biohazard bin."
        }
        show {
            title "Done!"
            note "Thank you. You are all done with the microscope task."
        }

        if io_hash[:task_id]
            task = find(:task, id: io_hash[:task_id])[0]
            set_task_status(task,"microscope_lens_ready")
        end

        return { io_hash: io_hash }


    end
end
