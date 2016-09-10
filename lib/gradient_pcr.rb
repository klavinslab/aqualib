module GradientPCR
  def distribute_pcrs fragment_info_list, num_therm
    frags_by_bins = sort_fragments_into_bins fragment_info_list, num_therm
    frags_by_bins.reject { |frag_hash| frag_hash[:rows].empty? }.map do |frag_hash|
      { 
        fragment_info: frag_hash[:rows], bins: frag_hash[:bins], mm: 0, ss: 0, fragments: [], templates: [], forward_primers: [],
        reverse_primers: [], forward_primer_ids: [], reverse_primer_ids: [], stripwells: [], tanneals: [] 
      }
    end
  end

  def sort_fragments_into_bins fragment_info_list, num_therm
    temps_by_bins = sort_temperatures_into_bins fragment_info_list.map { |fi| fi[:tanneal] }, num_therm

    fragment_info_list_copy = Array.new fragment_info_list
    temps_by_bins.map do |grad_hash|
      frag_hash = { bins: grad_hash[:bins], rows: Hash.new { |h, k| h[k] = [] } }
      grad_hash[:rows].each do |b, ts|
        frag_hash[:rows][b] += ts.map do |t|
          frag_info = fragment_info_list_copy.find { |fi| fi[:tanneal] == t }
          #puts "fragment_info_list_copy: #{fragment_info_list_copy.length}\nfrag_info: #{frag_info}\ntemperature: #{t}"
          #fragment_info_list_copy -= [frag_info]
          fragment_info_list_copy.delete_at(fragment_info_list_copy.index(frag_info))
          frag_info
        end
      end
      frag_hash
    end
  end

  def sort_temperatures_into_bins an_temps, num_therm
    bins = [0.0, 0.75, 2.0, 3.7, 6.1, 7.9, 9.3, 10.0]
    #an_temps = Array.new(8) { rand(560..720) }.sort.map { |t| t / 10.0 }
    puts "\n#{"Annealing temperatures:"} #{an_temps.to_s}"
    #an_temps = [56, 59.3, 72, 71.4, 70, 64, 63.4, 63.4, 67, 67, 68, 72, 57, 71.5, 56.9]
    #an_temps = [56.0, 59.9, 60.0, 63.8, 64.3, 70.0]
    #an_temps = [58.0, 58.7, 60.4, 60.6, 62.3, 62.4, 67.4, 71.8]
    #an_temps = [58.1, 59.1, 59.9, 62.9, 65.2, 70.6, 71.4, 72.0]
    #an_temps = [56.2, 58.6, 61.1, 62.4, 63.1, 65.6, 67.5, 69.4]
    #an_temps = [58.1, 58.3, 59.0, 61.5, 62.3, 63.4, 63.5, 70.8]
    #an_temps = [57.6, 58.0, 64.2, 66.8, 67.6, 69.2, 70.8, 71.8]

    best_bin_set = find_best_bin_set an_temps, bins, (56..62).map { |t| t / 1 }, Array.new, num_therm
    best_grad_set = make_grad_hash_set_from_bin_set(an_temps, best_bin_set)
    puts "\n#{"Best bin set:"} #{best_bin_set}"
    puts "\n#{"Best gradient set score:"} #{score_set best_grad_set}"
    puts "#{"Best gradient set: "} #{therm_format best_grad_set}"

    opt_best_grad_set = optimize_grad_set best_grad_set
    puts "\n#{"Best gradient set (optimized) score:"} #{score_set opt_best_grad_set}"
    puts "#{"Best gradient set (optimized): "} #{therm_format opt_best_grad_set}"
    puts opt_best_grad_set

    normal_bin_set = [[56],[60],[64],[67]]
    normal_grad_set = make_grad_hash_set_from_bin_set an_temps, normal_bin_set
    puts "\n#{"Normal gradient set score:"} #{score_bin_set an_temps, normal_bin_set}"
    puts "#{"Normal gradient set:"} #{therm_format normal_grad_set}"

    return opt_best_grad_set
  end

  def find_best_bin_set temps, bins, transforms, base_bin_set, num_bin_sets
    return base_bin_set if num_bin_sets == 0

    best_bin_set = nil
    transforms.each { |trans|
      t_bins = bins.map { |t| t + trans }
      next_base_bin_set = [t_bins] + base_bin_set
      next if (make_grad_hash temps, next_base_bin_set.flatten).nil?

      bin_set = (find_best_bin_set temps, bins, transforms[1..-1], next_base_bin_set, num_bin_sets - 1)
      best_bin_set ||= bin_set
      best_bin_set = bin_set if score_bin_set(temps, bin_set) < score_bin_set(temps, best_bin_set)
    }
    best_bin_set
  end

  def make_grad_hash temps, bins
    bin_rev = bins.reverse
    grad_hash = { bins: bins, rows: Hash.new { |h, k| h[k] = [] } }
    temps.each { |t|
      key = "#{bin_rev.find { |b| b <= t }}"
      return nil if key.empty?
      grad_hash[:rows][key].push t
    }
    grad_hash
  end

  def score grad_hash
    score = 0.0
    grad_hash[:rows].each { |b, ts|
      ts.each { |t| score = score + t - b.to_f }
    }
    score
  end

  def score_temps temps, bin
    temps.inject(0) { |sum, t| sum + t - bin }
  end

  def score_set grad_hash_set
    total = 0.0
    grad_hash_set.each { |grad_hash| total = total + score(grad_hash) }
    total.round(2)
  end

  def score_bin_set temps, bin_set
    grad_hash = make_grad_hash temps, bin_set.flatten.sort
    score(grad_hash).round(2)
  end

  def make_grad_hash_set_from_bin_set temps, bin_set
    grand_grad_hash = make_grad_hash temps, bin_set.flatten.sort
    bin_set.map { |bins|
      row_hash = Hash.new
      bins.each do |b|
        if grand_grad_hash[:rows][b.to_s].any?
          row_hash[b.to_s] = grand_grad_hash[:rows][b.to_s]
          grand_grad_hash[:rows].delete(b.to_s)
        end
      end
      { bins: bins, rows: Hash(row_hash.sort) }
    }
  end

  def optimize_grad_set grad_set
    grad_set.each_with_index do |grad_hash, idx|
      if grad_hash[:rows].length <= 1 # Can take another temperature set
        high_score_hash_and_bin = find_highest_scoring_hash_and_bin grad_set, grad_hash
        if !high_score_hash_and_bin[:hash].empty? # Move highest scoring temperature set to this grad_hash
        	#puts high_score_hash_and_bin
          hs_bin = high_score_hash_and_bin[:bin]
          hs_ts = high_score_hash_and_bin[:hash][hs_bin]
          grad_hash[:rows].merge!({ hs_bin => hs_ts }) { |bin, ts1, ts2| ts1 + ts2 }
          high_score_hash_and_bin[:hash].delete(hs_bin)
        end
        if grad_hash[:rows].length == 1 && grad_set[(idx + 1)..-1].any? { |gh| gh[:rows].length == 1 } # Move isolated temperature set to this grad_hash
          targ_hash = grad_set[(idx + 1)..-1].find { |gh| gh[:rows].length == 1 }
          targ_bin = targ_hash[:rows].keys.find { |b| targ_hash[:rows][b].any? }
          #puts "GRAD1: " + grad_hash.to_s
          grad_hash[:rows].merge!({ targ_bin => targ_hash[:rows][targ_bin] }) { |bin, ts1, ts2| ts1 + ts2 }
          #puts "GRAD2: " + grad_hash.to_s
          targ_hash[:rows].delete(targ_bin)
          #puts "HEY"
        end
      end

      update_rows grad_hash
    end
    
    grad_set.each { |grad_hash| update_rows grad_hash }
  end

  def update_rows grad_hash  
    if grad_hash[:rows].length == 1 # Set single temperature
      #puts grad_hash
      row = grad_hash[:rows].values.first
      grad_hash[:rows] = { row.min.to_s => row.sort }
      grad_hash[:bins] = [row.min]
      #puts grad_hash
      #puts "WAAT"
    elsif grad_hash[:rows].length == 2 # Set the upper and lower temperature bounds
      rows = grad_hash[:rows].values
      grad_hash[:rows] = { rows.first.min.to_s => rows.first.sort, rows.last.min.to_s => rows.last.sort }
      grad_hash[:bins] = [grad_hash[:rows].keys.min.to_f, grad_hash[:rows].keys.max.to_f].sort
      #puts "WOOT"
    end
  end

  def num_bins_with_any_temps_set grad_set
    #puts "WAAAAAFAFLDKSJFSLDKJF: " + grad_set.to_s
    grad_set.map { |gh| gh[:rows].values.inject(0) { |sum, ts| sum + (ts.any? ? 1 : 0) } }
  end

  def find_highest_scoring_hash_and_bin grad_set, grad_hash
    high_score_hash_and_bin = nil
    grad_set.each { |gh|
      next if gh == grad_hash || gh[:rows].length <= 2
      gh[:rows].each { |b, ts|
        high_score_hash_and_bin ||= { hash: gh[:rows], bin: b }
        hs_bin = high_score_hash_and_bin[:bin]
        hs_ts = high_score_hash_and_bin[:hash][hs_bin]
        #puts "high score: " + high_score_hash_and_bin.to_s
        #puts "gh: " + gh.to_s
        if score_temps(ts, b.to_f) > score_temps(hs_ts, hs_bin.to_f)
          high_score_hash_and_bin = { hash: gh[:rows], bin: b }
        end
      }
    }
    #puts high_score_hash_and_bin.to_s
    high_score_hash_and_bin || { hash: {}, bin: "" }
  end

  def therm_format grad_set
    str = ""
    grad_set.each_with_index { |grad_hash, idx|
      str += "\n#{"Therm #{idx + 1}:"} Set gradient #{grad_hash[:bins].first}-#{grad_hash[:bins].last}"
      grad_hash[:rows].each { |b, ts|
        str += "\n    #{b}: #{ts.to_s}"
      }
    }
    str
  end
end

class String
  # colorization
  def colorize(color_code)
    "\e[#{color_code}m#{self}\e[0m"
  end

  def red
    colorize(31)
  end

  def green
    colorize(32)
  end

  def yellow
    colorize(33)
  end

  def blue
    colorize(34)
  end

  def pink
    colorize(35)
  end

  def light_blue
    colorize(36)
  end

  def gray
    colorize(37)
  end

  def bold
    colorize(1)
  end
end