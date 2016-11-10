needs "aqualib/lib/cloning"
needs "aqualib/lib/standard"

class Protocol

  include Cloning
  include Standard
  require 'matrix'

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

  def ensure_5ul_total volumes
    max = volumes.max
    total = volumes.reduce(:+)
    volumes[volumes.index(max)] = max - (total - 5) if total > 5
    volumes
  end

  def verify_stock_volumes frag_stocks
    need_to_measure = false
    frag_stocks.each do |fs|
      if fs.datum[:volume_verified] != "Yes"
        need_to_measure = true
        break
      end
    end

    if need_to_measure

      fragment_volume = show {
        title "Estimate volume of fragment stock"
        warning "Pause here, don't click through until you entered estimated volume.".upcase
        frag_stocks.each do |fs|
          if fs.datum[:volume_verified] != "Yes"
            get "number", var: "v#{fs.id}", label: "Estimate volume for tube #{fs.id}, normally a number less than 28", default: 28
          end
        end
      }

      # write into datum the verified volumes
      frag_stocks.each do |fs|
        volume = fragment_volume[:"v#{fs.id}".to_sym]
        if volume
          fs.datum = fs.datum.merge({ volume: volume, volume_verified: "Yes" })
          fs.save
        end
      end

    end
  end # verify_stock_volume

  def remove_zero_volumes frag_stocks, not_enough_volume_stocks, replacement_stocks
    frag_stocks.each { |frag|
      if frag.datum[:volume].zero?
      end
    }
  end # remove_zero_volumes

  def find_replacement_stock frag_stock, not_enough_volume_stocks
    i = 1
    replacement = frag_stock.sample.in("Fragment Stock")[i]
    while (not_enough_volume_stocks.include? replacement)
      i += 1
      replacement = frag_stock.sample.in("Fragment Stock")[i]
    end
    replacement
  end # find_replacement_stock

  def update_batch_matrix batch, num_samples
    rows = batch.matrix.length
    columns = batch.matrix[0].length
    batch.matrix = fill_array rows, columns, num_samples, find(:sample, name: "Gibson Aliquot")[0].id
    batch.save
  end # update_batch_matrix

  def update_gibson_batches batch, old_batch, test_batch, used_aliquots
    # used_aliquots functionality to add or subtract aliquots as the users used them
    if test_batch && test_batch.datum[:tested] == "Yes"
      update_batch_matrix test_batch, (test_batch.num_samples - 1)
      used_aliquots -= 1
    end
    if old_batch && old_batch.num_samples > used_aliquots
      update_batch_matrix old_batch, (old_batch.num_samples - used_aliquots)
    else
      if old_batch
        used_aliquots -= old_batch.num_samples
        update_batch_matrix old_batch, 0
        old_batch.mark_as_deleted
        old_batch.save
      end
      update_batch_matrix batch, (batch.num_samples - used_aliquots)
    end
  end

  def arguments
    {
      io_hash: {},
      #Enter the fragment sample ids as array of arrays, eg [[2058,2059],[2060,2061],[2058,2062]]
      fragment_ids: [[4275,2059,2058,3951],[4275,2059],[663,27,28,284],[2059,4275],[3951,3952]],
      #Tell the system if the ids you entered are sample ids or item ids by enter sample or item, sample is the default option in the protocol.
      sample_or_item: "sample",
      #Enter correspoding plasmid id or fragment id for each fragment to be Gibsoned in.
      plasmid_ids: [5985,12648,12980,5205,5986],
      debug_mode: "No",
    }
  end

  def main
    io_hash = input[:io_hash]
    io_hash = input if !input[:io_hash] || input[:io_hash].empty?

    # setup default values for io_hash.
    io_hash = { backbone_ids: [], inserts_ids: [], restriction_enzyme_ids: [], task_ids: [], debug_mode: "No" }.merge io_hash

    # Set debug based on debug_mode
    if io_hash[:debug_mode].downcase == "yes"
      def debug
        true
      end
    end

    show {
      note io_hash
    }

    io_hash[:task_ids].each do |tid|
      task = find(:task, id: tid)[0]
      set_task_status(task,"gibson")
    end
    io_hash[:gibson_result_ids] = gibson_results.collect {|g| g.id}
    return { io_hash: io_hash }
  end

end
