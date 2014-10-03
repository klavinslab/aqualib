needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning


  def arguments
    {
      io_hash: {}
    }
  end

  def main

    answer = "No"
    arrived = "No"

    while answer == "No"
      check_store = show {
        title "Call the biochem store to see if primers have arrived."
        check "On the lab phone, dial 31728"
        check "If someone answers, politely ask the following: 'Hi, I am calling from the Klavins Lab and was wondering if primers have arrived."
        select [ "Yes", "No" ], var: "answer", label: "Did anyone answer?", default: "No"
        select [ "Yes", "No", "They did not answer..." ], var: "arrived", label: "Did any primers arrive?", default: "No"
      }
      answer = check_store[:answer]
      arrived = check_store[:arrived]

      show {
        title "Wait 15 minutes and call again"
      } if answer == "No"
    end

    primer_stocks = []
    if answer == "Yes"
      show {
        title "Go the biochem store to pick up primers"
        note "Walk accross the campus to the biochem store to pick up primers."
      }

      show {
        title "Quick spin down all the primer tubes"
        note "Put all the primer tubes in table top centrifuge to spin down for 3 seconds"
        warning "Make sure to balance"
      }

      primers_info = show {
        title "How many primer tubes do you got?"
        get "number", var: "num", label: "Enter a number", default: 0
      }

      (1..primers_info[:num]).each do |i|
        primer = show {
          title "Grab one primer tube"
          get "number", var: "primer_id", label: "Enter primer ID number, which is listed before the primer's name on the side of the tube.", default: 0
          get "number", var: "mole", label: "Enter the number of moles of primer in the tube, in nm. This is written toward the bottom of the tube, below the MW.", default: 0
        }
        primer_id = primer[:primer_id]
        primer_mole = primer[:mole]
        primer_stock = produce new_sample find(:sample,{id: primer_id})[0].name, of: "Primer", as: "Primer Stock"
        primer_stocks.push primer_stock

        show {
          title "Rehydrate the primer"
          note "Add #{primer_mole*10} µL of TE into the primer tube"
          note "Label the tube with #{primer_stock} using white dot label"
        }
      end
      
      show {
        title "Wait one minute for the primer to dissolve in TE"
        timer initial: { hours: 0, minutes: 1, seconds: 0}
      }
        
      show {
        title "Vortex and centrifuge"
        note "Vortex each tube on table top vortexer for 10 seconds and then quick spin for 2 seconds on table top centrifuge"
      }

      release primer_stocks, interactive: true,  method: "boxes"

    end


  end

end
