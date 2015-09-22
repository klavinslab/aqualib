needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

#doc https://github.com/klavinslab/aquarium/blob/master/doc/Krill.md

class Protocol

    include Standard
    include Cloning

    def arguments
        {
            overnight_id: 36164,
            debug_mode: "No"
        }
    end

    def main
        if input[:debug_mode].downcase == "yes"
            def debug
                true
            end
        end

        overnight_id = input[:overnight_id]
        overnight_in_aq = find(:item, id: overnight_id)[0]

        #use take items
        #take items, interactive: true

        #
        show {
            title "Dillute overnight"
            note "We will perform a 1:100 dillution of the overnight in a centrifuge tube."
        }


        #
        show {
            title "Get items"
            note "Take Plate #{overnight_id} at #{overnight_in_aq.location}"
            note "Take a centrifuge tube from XXXX. Label it with #{overnight_id}_D."
        }
        show {
            title "Get media"
            note "Put 1mL of YAPD in the centrifuge tube #{overnight_id}_D."
        }
        #
        show {
            title "Dillute overnight"
            note "Pipette 1uL of the overnight #{overnight_id} into the centrifuge tube #{overnight_id}_D."
        }
        #
        show {
            title "Return items"
            note "Return #{overnight_id} to #{overnight_in_aq.location}"
            note "Return #{overnight_id}_D in the 30C shaker incubator. After 5 hours, the yeast should be ready to be imaged."
        }


    end
end
