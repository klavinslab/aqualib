needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

# please use the sample id (not the item id) as suffix when ordering primers from IDT.

class Protocol

  include Standard
  include Cloning
  require 'set'

  def debug
    false
  end

  def arguments
    {
      io_hash: {},
      debug_mode: "No",
      group: "cloning"
    }
  end

  def main
    io_hash = input[:io_hash]
    io_hash = input if !input[:io_hash] || input[:io_hash].empty?
    if io_hash[:debug_mode].downcase == "yes"
      def debug
        true
      end
    end
    io_hash = { primer_ids:[] }.merge io_hash

    answer = "No"
    arrived = "No"

    while answer == "No"
      check_store = show {
        title "Call the biochem store to see if primers have arrived."
        check "On the lab phone, dial 31728."
        check "If someone answers, politely ask the following: 'Hi, I am calling from the Klavins Lab and was wondering if primers have arrived."
        select [ "Yes", "No" ], var: "answer", label: "Did anyone answer?", default: "Yes"
        select [ "Yes", "No", "They did not answer..." ], var: "arrived", label: "Did any primers arrive?", default: "Yes"
      }
      answer = check_store[:answer]
      arrived = check_store[:arrived]

      show {
        title "Wait 15 minutes and call again"
      } if answer == "No"
      
    end

    primer_stocks = []
    primer_stocks_to_dilute = []
    primer_aliquots = []
    if answer == "Yes"
      show {
        title "Go the biochem store to pick up primers"
        note "Walk accross the campus to the biochem store to pick up primers."
      }

      show {
        title "Quick spin down all the primer tubes"
        note "Put all the primer tubes in table top centrifuge to spin down for 3 seconds."
        warning "Make sure to balance!"
      }

      primers_info = show {
        title "How many primer tubes do you got?"
        get "number", var: "num", label: "Enter a number", default: 1
      }

      i = 0
      while i < primers_info[:num]
        primer = show {
          title "Grab one primer tube"
          get "number", var: "primer_id", label: "Enter primer ID number, which is listed before the primer's name on the side of the tube.", default: 2054
          get "number", var: "mole", label: "Enter the number of moles of primer in the tube, in nm. This is written toward the bottom of the tube, below the MW.", default: 10
        }
        primer_id = primer[:primer_id]
        primer_mole = primer[:mole]
        primer_sample = find(:sample,{id: primer_id})[0]

        if primer_sample.sample_type.name == "Primer"
          primer_stock = produce new_sample primer_sample.name, of: "Primer", as: "Primer Stock"
          primer_stocks.push primer_stock
          if primer_stock.sample.properties["Anneal Sequence"][1] != "*"
            show {
              title "Rehydrate the primer"
              note "Add #{primer_mole*10} µL of TE into the primer tube"
              note "Label the tube with #{primer_stock} using white dot label"
            }
            primer_stocks_to_dilute.push primer_stock 
          else
            show {
              title "Rehydrate the primer"
              note "Add #{primer_mole*10} µL of water into the primer tube"
              note "Label the tube with #{primer_stock} using white dot label"
              warning "Add water to this sample, not TE!"
            }
          end
          i += 1
        else
          primer_check = show {
            title "Sample id error"
            select [ "Yes", "No" ], var: "id_correct", label: "The number you entered is not a primer sample id. Did you enter it correctly?", default: "No"
          }
          if primer_check[:id_correct] == "Yes"
            i += 1 
            show {
              title "Inform the primer owner about id error"
              note "Email or tell the primer owner that their primer sample id has problems"
            }
          end
        end
      end
      if primer_stocks.length > 0
        show {
          title "Wait one minute for the primer to dissolve in TE"
          timer initial: { hours: 0, minutes: 1, seconds: 0}
        } 
        show {
          title "Vortex and centrifuge"
          note "Vortex each tube on table top vortexer for 5 seconds and then quick spin for 2 seconds on table top centrifuge"
        }
      end

      if primer_stocks_to_dilute.length > 0
        primer_aliquots = primer_stocks_to_dilute.collect { |p| produce new_sample p.sample.name, of: "Primer", as: "Primer Aliquot" }
        show {
          title "Grab #{primer_aliquots.length} 1.5 mL tubes"
          check "Grab #{primer_aliquots.length} 1.5 mL tubes, label with following ids."
          check primer_aliquots.collect { |p| "#{p}"}
          check "Add 90 µL of water into each above tube."
        }
        show {
          title "Make primer aliquots"
          note "Add 10 µL from primer stocks into each primer aliquot tube using the following table."
          table [["Primer Aliquot id", "Primer Stock, 10 µL"]].concat (primer_aliquots.collect { |p| "#{p}"}.zip primer_stocks_to_dilute.collect { |p| { content: p.id, check: true } })
        }
      end
    end
    release primer_stocks + primer_aliquots, interactive: true,  method: "boxes"
    primer_ids = primer_stocks.collect { |x| x.sample.id }
    if io_hash[:primer_ids].to_set.subset? primer_ids.to_set
      if io_hash[:task_ids]
        io_hash[:task_ids].each do |tid|
          task = find(:task, id: tid)[0]
          set_task_status(task,"received and stocked")
        end
      end
    end

    return { io_hash: io_hash }

  end

end
