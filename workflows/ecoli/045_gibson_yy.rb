needs "protocols/mutagenesis_workflow/lib/standard"
needs "protocols/mutagenesis_workflow/lib/cloning"

class Protocol

  include Standard
  include Cloning
  require 'matrix'

  def debug
    true
  end

  def arguments
    {
      io_hash: {},
      #Enter the fragment sample id or item id as a list, eg [2048,2049,2060,2061,2,2]
      fragment_ids: [2058,2059,2060,2061,2062],
      #Tell the system if the ids you entered are sample ids or item ids by enter sample or item
      sample_or_item: "sample",
      #Tell the system how the fragments are grouped to perform Gibson reaction. e.g. [3,2] represents the first 3 fragments are in one Gibson reaction and the last 2 fragments are in another Gibson reaction.
      group_info: [3,2],
      #Enter correspoding plasmid id or fragment id for each fragment to be Gibsoned in.
      plasmid_ids: [2236,1923]
    }
  end

  def gibson_vector row
    if row == 0
      return 5.0
    else
      return 0
    end
  end

  def gibson_coefficients row, col, conc_over_length
    if row == 0
      return 1
    elsif col == 0
      return conc_over_length[0]
    elsif row == col
      return -conc_over_length[row]
    else
      return 0
    end
  end

  def main
    #check if inputs are correct
    raise "Incorrect group info inputs, does not match number of fragments" if input[:group_info].inject{|sum,x| sum + x } != input[:fragment_ids].length
    raise "Incorrect group info inputs, does not match numer of plasmids" if input[:group_info].length != input[:plasmid_ids].length
    
    io_hash = input[:io_hash]
    io_hash = input if input[:io_hash].empty?


    show {
      title "Testing page"
      note "io_hash is now input" if not io_hash.empty?
    }
    #find fragment stocks, concentrations and lengths
    fragment_stocks = input[:fragment_ids].collect{|fid| find(:sample,{id: fid})[0].in("Fragment Stock")[0]} if input[:sample_or_item] == "sample"
    fragment_stocks = input[:fragment_ids].collect{|fid| find(:item, id: fid )[0]} if input[:sample_or_item] == "item"

    # build an array of arrays for fragments stocks based on the group info
    fragment_stocks_arr = []
    i = 0
    input[:group_info].each do |info|
      fragment_stocks_sub = fragment_stocks[i..(i+info-1)]
      fragment_stocks_arr.push fragment_stocks_sub
    end

    fragment_volumes = []
    fragment_stocks_arr.each do |fs|
      conc_over_length = fs.collect{|f| f.datum[:concentration].to_f/f.sample.properties["Length"]}
      num = conc_over_length.length
      total_vector = Matrix.build(num, 1) {|row, col| gibson_vector row}
      coefficient_matrix = Matrix.build(num, num) {|row, col| gibson_coefficients row, col, conc_over_length}
      volume_vector = coefficient_matrix.inv * total_vector
      volumes = volume_vector.each.to_a
      fragment_volumes.push volumes 
    end

    # produce Gibson reaction results ids
    plasmid_ids = input[:plasmid_ids]
    gibson_ids = []
    gibson_results = []
    plasmid_ids.each_with_index do |pid,idx|
      plasmid = find(:sample,{id: pid})[0]
      gibson_result = produce new_sample plasmid.name, of: "Plasmid", as: "Gibson Reaction Result"
      gibson_results = gibson_results.push gibson_result
      gibson_ids = gibson_ids.push gibson_result.id
    end

    # Tell the user what we are doing
    show {
      title "Fragment Information"
      note "This protocol will build the following plasmids using Gibson Assembly method:"
      note plasmid_ids.collect {|p| "#{p}"}
    }

    # Take fragment stocks
    take fragment_stocks, interactive: true,  method: "boxes"

    # Take Gibson aliquots and label with Gibson Reaction Result ids
    show {
      title "Take Gibson Aliquots and label them with ids"
      note "Take #{gibson_ids.length} Gibson Aliquots from SF2.100"
      note "Label each Gibson Aliquot with the following ids using round dot labels"
      note (gibson_ids.collect {|gid| "#{gid}"})
    }

    # following loop is to show a table of setting up each Gibson reaction to the user
    k = 0  # set a index outside the loop to track which groups of Gibson fragments are being worked on
    gibson_ids.each_with_index do |gid,idx|
      group_size = input[:group_info][idx]
      tab = [["Gibson Reaction ids","Fragment Stock ids","Volume (µL)"]]
      fragment_stocks_arr[idx].each_with_index do |f,m|
        tab.push([gid,"#{f.id}",{ content: fragment_volumes[idx][m].round(1), check: true }])
      end
      k += group_size
      show {
          title "Load Gibson Reaction #{gid}"
          table tab
        } 
    end

    # Place all reactions in 50 C heat block
    show {
      title "Place on a heat block"
      note "Put all Gibson Reaction tubes on the 50 C heat block located in the back of bay B3."
    }

    release fragment_stocks, interactive: true,  method: "boxes"

    show {
      title "Wait for 60 minutes"
      note "Please start a timer by yourself"
    }

    release gibson_results, interactive: true,  method: "boxes"
  end

end