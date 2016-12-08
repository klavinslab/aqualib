needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning
  require 'matrix'

  def arguments
    {
      io_hash: {},
      #Enter the DNA sample ids as array of arrays, eg [[2058,2059],[2060,2061],[2058,2062]]
      plasmid_ids: [[82379]],
      dna_amount: [[1]],
      #Tell the system if the ids you entered are sample ids or item ids by enter sample or item, sample is the default option in the protocol.
      sample_or_item: "item",
      debug_mode: "Yes",
    }
  end

  def main
    io_hash = input[:io_hash]
    io_hash = input if !input[:io_hash] || input[:io_hash].empty?

    # setup default values for io_hash.
    io_hash = { plasmid_ids: [], dna_amount:[], debug_mode: "No", item_choice_mode: "No" }.merge io_hash

    # Set debug based on debug_mode
    if io_hash[:debug_mode].downcase == "yes"
      def debug
        true
      end
    end

    # Find fragment stocks into array of arrays
    plasmid_stocks_array = io_hash[:plasmid_ids].collect{|pids| pids.collect {|pid| find(:item, {id: pid})[0]}}
    plasmid_stocks_flatten = plasmid_stocks_array.flatten.uniq

    take plasmid_stocks_flatten, interactive: true,  method: "boxes"

    plasmid_stocks_need_to_measure = plasmid_stocks_flatten.select {|f| !f.datum[:concentration]}
    if plasmid_stocks_need_to_measure.length > 0
      data = show {
        title "Nanodrop the following plasmid stocks."
        plasmid_stocks_need_to_measure.each do |x|
          get "number", var: "c#{x.id}", label: "Go to B9 and nanodrop tube #{x.id}, enter DNA concentrations in the following", default: 30.2
        end
      }
      plasmid_stocks_need_to_measure.each do |x|
        x.datum = {concentration: data[:"c#{x.id}".to_sym]}
        x.save
      end
    end
 
    # For each reaction, calculate the volume of plasmid required
    show {
        title "Debug"
        plasmid_stocks_array.each do |p|
          note "plasmid_stocks #{p}"
        end
      }
      
#     fragment_volumes = []
#     fragment_stocks.each do |fs|
#       conc_over_length = fs.collect{|f| f.datum[:concentration].to_f/f.sample.properties["Length"]}
#       num = conc_over_length.length
#       total_vector = Matrix.build(num, 1) {|row, col| gibson_vector row}
#       coefficient_matrix = Matrix.build(num, num) {|row, col| gibson_coefficients row, col, conc_over_length}
#       volume_vector = coefficient_matrix.inv * total_vector
#       volumes = volume_vector.each.to_a
#       volumes.collect! { |x| x < 0.5 ? 0.5 : x }
#       fragment_volumes.push volumes
#     end

    # Measure not verified volumes of fragment stocks
#     need_to_measure = false
#     fragment_stocks_flatten.each do |fs|
#       if fs.datum[:volume_verified] != "Yes"
#         need_to_measure = true
#         break
#       end
#     end

#     if need_to_measure

#       fragment_volume = show {
#         title "Estimate volume of fragment stock"
#         warning "Pause here, don't click through until you entered estimated volume.".upcase
#         fragment_stocks_flatten.each do |fs|
#           if fs.datum[:volume_verified] != "Yes"
#             get "number", var: "v#{fs.id}", label: "Estimate volume for tube #{fs.id}, normally a number less than 28", default: 28
#           end
#         end
#       }

#       # write into datum the verified volumes
#       fragment_stocks_flatten.each do |fs|
#         if fragment_volume[:"v#{fs.id}".to_sym]
#           fs.datum = fs.datum.merge({ volume: fragment_volume[:"v#{fs.id}".to_sym], volume_verified: "Yes" })
#           fs.save
#         end
#       end

#     end

#     # Take Gibson aliquots and label with Gibson Reaction Result ids
#     show {
#       title "Take Gibson Aliquots"
#       note "Take #{io_hash[:plasmid_ids].length} Gibson Aliquots from SF2.100, put on an ice block."
#       warning "Keep all gibson aliquots cool on ice."
#     }

#     # following loop is to show a table of setting up each Gibson reaction to the user
#     gibson_results = []
#     empty_fragment_stocks = []
#     not_done_task_ids = []
#     all_replacement_stocks = []
#     io_hash[:plasmid_ids].each_with_index do |pid,idx|
#       plasmid = find(:sample,{id: pid})[0]
#       gibson_result = produce new_sample plasmid.name, of: "Plasmid", as: "Gibson Reaction Result"

#       tab = [["Gibson Reaction ids","Fragment Stock ids","Volume (µL)"]]
#       fragment_stocks[idx].each_with_index do |f,m|
#         tab.push(["#{gibson_result}","#{f}",{ content: fragment_volumes[idx][m].round(1), check: true }])
#         new_volume = (f.datum[:volume] || fragment_volume[:"v#{f.id}".to_sym]) - fragment_volumes[idx][m].round(1)
#         f.datum = f.datum.merge({ volume: new_volume.round(1) })
#         f.save
#         empty_fragment_stocks.push f if new_volume < 1
#       end
#       volume_empty = show {
#         title "Load Gibson Reaction #{gibson_result}"
#         note "Lable an unused gibson aliquot as #{gibson_result}."
#         note "Make sure the gibson aliquot is thawed before pipetting."
#         table tab
#         fragment_stocks[idx].each do |f|
#           select ["Yes", "No"], var: "c#{f.id}", label: "Does #{f.id} have enough volume for this reaction?", default: "Yes"
#         end if io_hash[:debug_mode].downcase != "yes"
#       }

#       # deal with not enough volume situation
#       not_enough_volume_stocks = []
#       replacement_stocks = []

#       fragment_stocks[idx].each_with_index do |f, idy|
#         if volume_empty[:"c#{f.id}".to_sym] == "No"
#           not_enough_volume_stocks.push f
#           if f.sample.in("Fragment Stock")[1]
#             replacement_stocks.push f.sample.in("Fragment Stock")[1]
#             fragment_stocks[idx][idy] = f.sample.in("Fragment Stock")[1]
#           end
#         end
#       end

#       all_replacement_stocks.concat replacement_stocks

#       if not_enough_volume_stocks.length > 0

#         if replacement_stocks.length == not_enough_volume_stocks.length
#           take replacement_stocks, interactive: true
#           gibson_results = gibson_results.push gibson_result
#           tab = [["Gibson Reaction ids","Fragment Stock ids","Volume (µL)"]]
#           fragment_stocks[idx].each_with_index do |f,m|
#             tab.push(["#{gibson_result}","#{f}",{ content: fragment_volumes[idx][m].round(1), check: true }])
#           end
#           show {
#             title "Load Gibson Reaction #{gibson_result} with new stocks"
#             note "Make sure the gibson aliquot is thawed before pipetting."
#             table tab
#           }
#         else
#           show {
#             title "Throw away the unfinished gibson aliquot"
#             note "Discard #{gibson_result}"
#           }
#           delete gibson_result
#           not_done_task_ids.push io_hash[:task_ids][idx] if io_hash[:task_ids]

#         end

#         empty_fragment_stocks.concat not_enough_volume_stocks

#       else

#         gibson_results = gibson_results.push gibson_result

#       end


#     end

#     # Place all reactions in 50 C heat block
#     show {
#       title "Place on a heat block"
#       note "Put all Gibson Reaction tubes on the 50 C heat block located in the back of bay B3."
#     }

#     move gibson_results, "50 C heat block"
#     release gibson_results

#     show {
#       title "Discard the following fragment stocks"
#       note empty_fragment_stocks.collect { |f| "#{f}"}
#     } if empty_fragment_stocks.length > 0

#     all_replacement_stocks.uniq!

#     fragment_stocks_to_release = fragment_stocks_flatten - empty_fragment_stocks + all_replacement_stocks

#     delete empty_fragment_stocks

#     # Release fragment stocks flatten
#     release fragment_stocks_to_release, interactive: true,  method: "boxes"

#     not_done_task_ids.each do |tid|
#       task = find(:task, id: tid)[0]
#       set_task_status(task,"waiting")
#       task.notify "Pushed back to waiting, not enought volume for fragment stocks, new fragment stocks will be made during next fragment construction batch.", job_id: jid
#     end

#     if io_hash[:task_ids]
#       io_hash[:task_ids] = io_hash[:task_ids] - not_done_task_ids
#       io_hash[:task_ids].each do |tid|
#         task = find(:task, id: tid)[0]
#         set_task_status(task,"gibson")
#       end
#     end
#     io_hash[:gibson_result_ids] = gibson_results.collect {|g| g.id}
#     return { io_hash: io_hash }
  end

end
