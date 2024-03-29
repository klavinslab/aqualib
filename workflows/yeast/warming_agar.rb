needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol
  include Standard
  include Cloning

  def arguments 
    {
    io_hash: {},
    debug_mode: "Yes"   
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

    io_hash[:size_agar].blank? ? size = io_hash[:size] : size = io_hash[:size_agar]

    for i in 0...(size)
      media = io_hash[:media_type][i]

      media_name = find(:sample, id: media)[0].name
      quantity = io_hash[:quantity][i]
      media_ingredients = media_name.split("-").map(&:strip).drop(1)
      acid_bank = ["His", "Trp", "Leu", "Ura"]
      present_acid = acid_bank - media_ingredients
      container = io_hash[:media_container][i]

      if container.include?("800 mL")
        multiplier = 1
      elsif container.include?("400 mL")
        multiplier = 0.5
      elsif container.include?("200 mL")
        multiplier = 0.25
      end

      acid_solutions = Array.new    
      present_acid.each do |i|
        if(i == "Leu")
            acid_solutions += [find(:item,{object_type:{name:"Leucine Solution"}})[0]]
        elsif(i == "His")
            acid_solutions += [find(:item,{object_type:{name:"Histidine Solution"}})[0]]
        elsif(i == "Trp")
            acid_solutions += [find(:item,{object_type:{name:"Tryptophan Solution"}})[0]]
        else
            acid_solutions += [find(:item,{object_type:{name:"Uracil Solution"}})[0]]
        end
      end

      agar = [find(:item, object_type: { name: "#{container}" }, sample_id: 11768)[0]] * quantity

       if acid_solutions.present?
        take agar + acid_solutions, interactive: true
       else
        take agar, interactive: true
       end

      show{
        title "Microwave SDO Agar"
        note "Microwave the SDO Agar at 70\% power for 2 minutes until all the agar is dissolved."
      }

      show{
        title "Add Amino Acids"
        note "Add #{multiplier * 8} mL of the following solution to each bottle(s):"
        present_acid.each do |i|
          check i
        end
      }

      show{
        title "Prepare Plates"
        note "Lay out approximately #{multiplier * 32} plates on the bench"
      }

      show{
        title "Pour Plates"
        note "Carefully pour ~25 mL into each plate. For each plate, pour until the agar completely covers the bottom of the plate."
        note "If there are a large number of bubbles in the agar, use a small amount of ethanol to pop them."
      }
      data = show{
        title "Record Number"
        note "Record the number of plates poured."
        get "number", var: "plates_poured", label: "Please record the number of plates.", default: 0
      }

      num = data[:plates_poured]
      plate_batch = produce new_collection "Agar Plate Batch", 10, 10
      batch_matrix = fill_array 10, 10, num, media
      plate_batch.matrix = batch_matrix
      plate_batch.location = "30 C incubator"
      plate_batch.save

      show{
        title "Wait For Plates to Solidify"
        note "Wait until all plates have completely solidified. This should take about 10 minutes."
      }

      show{
        title "Stack and Label"
        note "Stack the plates agar side up."
        note "Put a piece of labeling tape on each stack with '#{media_name}', '#{plate_batch}', 'your initials', and 'date'."
      }

        release [plate_batch], interactive: true
        io_hash = { plate_batch_id: [plate_batch.id] }.merge io_hash
      end
      return { io_hash: io_hash }
  end
end

  
