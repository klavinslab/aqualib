needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

#doc https://github.com/klavinslab/aquarium/blob/master/doc/Krill.md

class Protocol

    include Standard
    include Cloning

    def arguments
        {
          io_hash: {},
          plate_id: 36164,
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


        plate_id = input[:plate_id]
        plate_in_aq = find(:item, id: plate_id)[0]

        #use take items
        #take items, interactive: true



        show {
            note "Take Plate #{plate_id} at #{plate_in_aq.location}"

        }

        #
        show {
            title "Turn on the fluorescent light bulb"
            note "Labeled '1' and must be turned on first because it draws an extremely high current."
            warning "FAILURE TO DO THIS FIRST MAY RESULT IN A BROKEN SYSTEM."
            image "fluorescent lamp label 1"
        }




    end
end
