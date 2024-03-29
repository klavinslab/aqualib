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
        overnight_in_aq = find(:item, id: overnight_id)[0]

        #use take items
        #take items, interactive: true

        #
        show {
            title "Dillute overnight"
            note "We will perform a 1:1000 dillution of the overnight in a centrifuge tube."
        }


        #
        show {
            title "Get items"
            check "Take overnight #{overnight_id} at #{overnight_in_aq.location}"
            check "Take a centrifuge tube from B1.230. Label it with #{overnight_id}_D."
        }
        show {
            title "Get media"
            check "Put 1mL of YAPD in the centrifuge tube #{overnight_id}_D."
        }
        #
        show {
            title "Dillute overnight"
            check "Pipette 1uL of the overnight #{overnight_id} into the centrifuge tube #{overnight_id}_D."
        }
        #
        show {
            title "Return items"
            check "Return #{overnight_id} to #{overnight_in_aq.location}"
            check "Return #{overnight_id}_D in the 30C shaker incubator. After 5 hours, the yeasts should be ready to be imaged."
        }

        if io_hash[:task_id]
            task = find(:task, id: io_hash[:task_id])[0]
            set_task_status(task,"centrifuge_dilluted")
        end

        return { io_hash: io_hash }

    end
end
