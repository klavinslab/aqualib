needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning
  require 'matrix'

  def arguments
    {
      io_hash: {},
      #Enter the fragment sample id or item id as a list, eg [2048,2049,2060,2061,2,2]
      fragment_ids: [[2058,2059],[2060,2061],[2048,2058,2062]],
      #Tell the system if the ids you entered are sample ids or item ids by enter sample or item, sample is the default option in the protocol.
      sample_or_item: "sample",
      #Enter correspoding plasmid id or fragment id for each fragment to be Gibsoned in.
      plasmid_ids: [2236,1923,2573],
      debug_mode: "Yes",
      task_mode: "Yes"
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
    raise "Incorrect inputs, fragments group size does not match number of plasmids to be built" if input[:fragment_ids].length != input[:plasmid_ids].length
    #creat an empty io_hash for passing information
    io_hash = {}
    io_hash[:debug_mode] = input[:debug_mode]
    io_hash[:fragment_ids] = input[:fragment_ids]
    io_hash[:plasmid_ids] = input[:plasmid_ids]
    io_hash[:task_mode] = input[:task_mode]

    if io_hash[:debug_mode] == "Yes"
      def debug
        true
      end
    end

    if io_hash[:task_mode] == "Yes"
      gibson_info = gibson_assembly_status
      ready_task_ids = gibson_info[:assemblies][:ready_to_build]
      ready_task_ids.each do |tid|
        ready_task = find(:task, id: tid)[0]
        io_hash[:fragment_ids].push ready_task.simple_spec[:fragments]
        io_hash[:plasmid_ids].push ready_task.simple_spec[:target]
        ready_task.status = "running"
        ready_task.save
      end

    end

    #find fragment stocks, concentrations and lengths
    fragment_stocks = io_hash[:fragment_ids].collect{|fids| fids.collect {|fid| find(:sample,{id: fid})[0].in("Fragment Stock")[0]}}
    #Rewrite fragment_stocks if the input[:sample_or_item] is specified as item.
    fragment_stocks = io_hash[:fragment_ids].collect{|fids| fids.collect {|fid| find(:item,{id: fid})[0]}} if input[:sample_or_item] == "item"

    # build an array of arrays for fragments stocks based on the group info
    # fragment_stocks_arr = []
    # i = 0
    # input[:group_info].each do |info|
    #   fragment_stocks_sub = fragment_stocks[i..(i+info-1)]
    #   fragment_stocks_arr.push fragment_stocks_sub
    # end

    fragment_volumes = []
    fragment_stocks.each do |fs|
      conc_over_length = fs.collect{|f| f.datum[:concentration].to_f/f.sample.properties["Length"]}
      num = conc_over_length.length
      total_vector = Matrix.build(num, 1) {|row, col| gibson_vector row}
      coefficient_matrix = Matrix.build(num, num) {|row, col| gibson_coefficients row, col, conc_over_length}
      volume_vector = coefficient_matrix.inv * total_vector
      volumes = volume_vector.each.to_a
      fragment_volumes.push volumes 
    end

    # produce Gibson reaction results ids
    gibson_results = []
    io_hash[:plasmid_ids].each_with_index do |pid,idx|
      plasmid = find(:sample,{id: pid})[0]
      gibson_result = produce new_sample plasmid.name, of: "Plasmid", as: "Gibson Reaction Result"
      gibson_results = gibson_results.push gibson_result
    end

    # Tell the user what we are doing
    show {
      title "Fragment Information"
      note "This protocol will build the following plasmids using Gibson Assembly method:"
      note io_hash[:plasmid_ids].collect {|p| "#{p}"}
    }

    # Take fragment stocks, since fragment stocks are array of arrays, so use the flatten(1) method.
    take fragment_stocks.flatten(1), interactive: true,  method: "boxes"

    # Take Gibson aliquots and label with Gibson Reaction Result ids
    show {
      title "Take Gibson Aliquots and label them with ids"
      note "Take #{gibson_results.length} Gibson Aliquots from SF2.100"
      note "Label each Gibson Aliquot with the following ids using round dot labels"
      note (gibson_results.collect {|g| "#{g}"})
    }

    # following loop is to show a table of setting up each Gibson reaction to the user
    gibson_results.each_with_index do |g,idx|
      tab = [["Gibson Reaction ids","Fragment Stock ids","Volume (µL)"]]
      fragment_stocks[idx].each_with_index do |f,m|
        tab.push(["#{g}","#{f.id}",{ content: fragment_volumes[idx][m].round(1), check: true }])
      end
      show {
          title "Load Gibson Reaction #{g}"
          table tab
        } 
    end

    # Place all reactions in 50 C heat block
    show {
      title "Place on a heat block"
      note "Put all Gibson Reaction tubes on the 50 C heat block located in the back of bay B3."
    }

    # Release fragment stocks, since fragment stocks are array of arrays, so use the flatten(1) method.
    release fragment_stocks.flatten(1), interactive: true,  method: "boxes"

    show {
      title "Wait for 60 minutes"
      timer initial: { hours: 0, minutes: 60, seconds: 0}
    }

    release gibson_results, interactive: true,  method: "boxes"
  end

end