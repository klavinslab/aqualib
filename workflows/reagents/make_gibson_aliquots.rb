needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

#the above lines include the libraries from outside

class Protocol

#the following lines make the libraries available to the class
  include Standard
  include Cloning

  #arguments are the "variables" that will be available to the main, the debug_mode
  #command makes it possible to run the file without stoping at checkpoints i.e.
  #the show statements

    def arguments
      {
#        iso_buffer: 1023,
#        t5: 999,
#        phusion_pol: 57,
#        ligase: 40,
        debug_mode: "yes"
      }
    end

    def main

#this ensures that debug mode works
      if input[:debug_mode].downcase == "yes"
        def debug
          true
        end
      end

#takes inputs from arguments
#      iso_buffer = input[:iso_buffer]
      t5 = input[:t5]
      phusion_pol = input[:phusion_pol]
      ligase = input[:ligase]

      show {
        title "instructions"
        note "This protocol makes 80 gibson aliquots. Make sure you keep all associated enzyme in this prtocol ON ICE through the duration of the WHOLE PROTOCOL."

      }

      show {
        title "Chemicals Needed"
        note "This protocol uses the following"
        bullet "ISO_buffer"
        bullet "T5"
        bullet "Phusion Polymerase"
        bullet "DNA ligase"

      }


#checks to find stocks of all enzymes and buffers. Returns an error if stock isn't present
#      iso_stock = find(:sample, id: iso_buffer)[0].in("Enzyme Buffer Stock")[0]
#      iso_stock = find(:item, sample: { object_type: { name: "Enzyme Buffer" }, sample: { name: "5X ISO Buffer" } } )

      inventory_hash = {
        "5X ISO Buffer" => "Enzyme Buffer Stock",
        "T5 exonuclease" => "Enzyme Stock"
      }
      messages = []
      inventory_hash.each do |sample_name, container_name|
        stock = find(:sample, name: sample_name)[0].in(container_name)[0]
        messages.push "#{sample_name} does not have a #{container_name}"
      end

      if messages.any?
        show {
          title "Some stock is empty!"
          messages.each do |message|
            note message
          end
        }
        return
      end


       iso_buffer = find(:sample, name: "5X ISO Buffer" )[0]
       iso_stock = find(:sample, id: iso_buffer.id)[0].in("Enzyme Buffer Stock")[0]

        if iso_stock == nil
          show {
            title "Caution !!"
            note "This Buffer does not have a stock in the lab"
          }
          return
        end

        t5 = find(:sample, name: "T5 exonuclease" )[0]
        t5_stock = find(:sample, id: t5)[0].in("Enzyme Stock")[0]

        if t5_stock == nil
          show{
            title "Caution !!"
            note "This Enzyme does not have a stock in the lab"
            }
        end

        phusion_pol = find(:sample, name: "Phusion Polymerase" )[0]
        phu_stock = find(:sample, id: phusion_pol)[0].in("Enzyme Stock")[0]

        if phu_stock == nil
          show{
            title "Caution !!"
            note "This Enzyme does not have a stock in the lab"
          }
        end

        ligase = find(:sample, name: "Taq DNA Ligase" )[0]
        ligase_stock = find(:sample, id: ligase)[0].in("Enzyme Stock")[0]

        if ligase_stock == nil
          show{
            title "Caution !!"
            note "This Enzyme does not have a stock in the lab"
          }
        end

#if stock is found, then interatively shows where to take stocks from

        if iso_stock != nil
          take [iso_stock], interactive: true, method: "boxes"
          isEmpty = show{
            title "Technician Feedback Needed"
            get "text", var: "y", label: "Is the sample empty", default: "no"
            }
          if isEmpty[:y].downcase == "yes"
            iso_stock.mark_as_deleted
            iso_stock = find(:sample, id: iso_buffer.id)[0].in("Enzyme Buffer Stock")[0]
            if iso_stock == nil
              show{
                title "Caution !!"
                note "This Buffer does not have a stock in the lab"
              }
            end
            if iso_stock != nil
              take [iso_stock], interactive: true, method: "boxes"
            end
          end
        end


        if t5_stock != nil
          take [t5_stock], interactive: true, method: "boxes"
          isEmpty = show{
            title "Technician Feedback Needed"
            get "text", var: "y", label: "Is the sample empty", default: "no"
            }
          if isEmpty[:y].downcase == "yes"
            t5_stock.mark_as_deleted
            t5_stock = find(:sample, id: t5)[0].in("Enzyme Stock")[0]
            if t5_stock == nil
              show{
                title "Caution !!"
                note "This Enzyme does not have a stock in the lab"
              }
            end
            if t5_stock != nil
              take [t5_stock], interactive: true, method: "boxes"
            end
          end

        end

        if phu_stock != nil
          take [phu_stock], interactive: true, method: "boxes"
          isEmpty = show{
            title "Technician Feedback Needed"
            get "text", var: "y", label: "Is the sample empty", default: "no"
            }
          if isEmpty[:y].downcase == "yes"
            phu_stock.mark_as_deleted
            phu_stock = find(:sample, id: phusion_pol)[0].in("Enzyme Stock")[0]
            if phu_stock == nil
              show{
                title "Caution !!"
                note "This Enzyme does not have a stock in the lab"
              }
            end
            if phu_stock != nil
              take [phu_stock], interactive: true, method: "boxes"
            end
          end

        end

        if ligase_stock != nil
          take [ligase_stock], interactive: true, method: "boxes"
          isEmpty = show{
            title "Technician Feedback Needed"
            get "text", var: "y", label: "Is the sample empty", default: "no"
            }
          if isEmpty[:y].downcase == "yes"
            ligase_stock.mark_as_deleted
            ligase_stock = find(:sample, id: ligase)[0].in("Enzyme Stock")[0]
            if ligase_stock == nil
              show{
                title "Caution"
                note "This Enzyme does not have a stock in the lab"
              }
            end
            if ligase_stock != nil
              take [ligase_stock], interactive: true, method: "boxes"
            end
          end

        end


#protocol instructions
        show {
        note "Grab a sample cooling block from SF2 and place all items retrieved in it."
        title "Item assembly instruction"
        }

        show{
          title "Item assembly instruction"
          note "Grab a new 1.5 ml eppendorf tube and place it into the sample ice block"
        }

        show {
          title "Sample preparation instruction"
          check "Pipette 320µl of the 5X ISO buffer into the new eppendorf tube."
          check "Pipette 0.64µl of the T5 exonuclease into the eppendorf tube. Remember to keep all associated samples on the ice block."
          check "Pipette 20µl of the Phusion DNA Polymerase into the eppendorf tube."
          check "Pipette 160µl of the Taq DNA Ligase into the eppendorf tube."
          check "Add 699µl of MG H2O to the tube."
          check "Gently mix the eppendorf tube until contents are well mixed."
        }

        show {
          title "Prepare to pipette out aliquot"
          note "Grab 80 small sample tubes and another ice block with a 96well metal plate"
        }

        show {
          title "Pipette out aliquots"
          note "Aliquot 15µl of the eppendorf tube contents into each of the 80 small sample tubes"
        }

#release stocks interactively once the protocol is finished
        if iso_stock != nil
          release [iso_stock], interactive: true, method: "boxes"
        end

        if t5_stock != nil
          release [t5_stock], interactive: true, method: "boxes"
        end

        if phu_stock != nil
          release [phu_stock], interactive: true, method: "boxes"
        end

        if ligase_stock != nil
          release [ligase_stock], interactive: true, method: "boxes"
        end

#the produce part is still not very clear to me ... That needs to be filled in still

       j = produce new_object "Gibson Aliquot"
       loc_id = show {
         title "Technician Feedback Needed"
         get "text", var: "y", label: "Enter the location where you kept the aliquots", default: "no"
                }
                j.location = loc_id
       release [j]

      end
    end
