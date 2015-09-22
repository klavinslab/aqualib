needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

#doc https://github.com/klavinslab/aquarium/blob/master/doc/Krill.md

class Protocol

    include Standard
    include Cloning

    def arguments
        {
            debug_mode: "No"
        }
    end

    def main
        if input[:debug_mode].downcase == "yes"
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



    end
end
