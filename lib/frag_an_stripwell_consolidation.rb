module StripwellArrayOrganization
  def place_stripwells stripwells
    well_array = [[]]
    empty_wells = 12
    current_row = 0
    stripwells.each { |stripwell| # Place stripwells without cutting
      if 12 - well_array[current_row].length >= stripwell.num_samples # Add to existing row
        empty_wells -= stripwell.num_samples
        well_array[current_row].concat(Array.new(stripwell.num_samples) { stripwell })
      else  # Add to new row
        current_row += 1
        empty_wells += 12 - stripwell.num_samples
        well_array.push(Array.new(stripwell.num_samples) { stripwell })
      end
    }
    well_array
  end # place_stripwells

  def consolidate_stripwells well_array
    well_array_min_rows = well_array.flatten.enum_for(:each_slice, 12).to_a.length
    loop_num = 0; # Just in case we encounter an infinite loop
    while well_array.length > well_array_min_rows
      if loop_num > 100
        warning "Organizational error: Sorry, stripwell placement/cutting may not be optimized"
        break
      end
      loop_num += 1

      # Find row with most empty space
      row_lengths = well_array.map { |row| row.length }
      row_lengths.delete_at(-1) # The last row can never be consolidated into
      max_empty_index = row_lengths.index(row_lengths.min)

      # Consolidate below row with this row
      new_rows = well_array[max_empty_index..(max_empty_index + 1)].flatten.enum_for(:each_slice, 12).to_a

      # Replace old two rows with new_rows
      well_array = well_array[0...max_empty_index] + new_rows + well_array[max_empty_index + 2..-1]
    end
    return well_array
  end # consolidate_stripwells

  def create_analyzer_wells_array stripwells
    # Place stripwells in array without cutting
    analyzer_wells_array = place_stripwells stripwells
    # Cut stripwells to minimize rows and cuts
    consolidate_stripwells analyzer_wells_array
  end # create_analyzer_wells_array

  def find_cuts well_array
    cuts = Hash.new
    well_array.each { |row|
      # Record cut (cuts[cut_stripwell] = cut_index)
      last_stripwell = row[-1]
      last_stripwell_well_count = row.count { |stripwell| stripwell == last_stripwell }
      cuts["#{last_stripwell}"] = last_stripwell_well_count if last_stripwell.num_samples > last_stripwell_well_count
    }
    cuts
  end # find_cuts

  def stripwells_from_table stripwells, well_array
    all_wells = stripwells.collect { |stripwell| stripwell.matrix[0].select { |well| well != -1 } }.flatten
    all_task_id_mappings = stripwells.collect { |stripwell| stripwell.datum[:task_id_mapping] || Array.new(stripwell.num_samples) { -1 } }.flatten

    well_array.collect { |row|
      stripwells = row.uniq { |stripwell| stripwell.id }
      if stripwells.length == 1
        all_wells.slice!(0...stripwells[0].num_samples)
        all_task_id_mappings.slice!(0...stripwells[0].num_samples)
        stripwells[0]
      else
        new_stripwell = produce new_collection "Stripwell", 1, 12
        new_stripwell.matrix = [all_wells[0...row.length] + Array.new(12 - row.length) { -1 }]
        new_stripwell.datum = new_stripwell.datum.merge({ task_id_mapping: all_task_id_mappings[0...row.length] })
        all_wells.slice!(0...row.length)
        all_task_id_mappings.slice!(0...row.length)
        new_stripwell.save
        new_stripwell
      end
    }
  end # stripwells_from_table

  class Label
    @@num_labels = 0
    @stripwell
    @num_wells
    @second_half
    @label
    def initialize(stripwell, num_wells, second_half = false)
      extend RowNamer
      @stripwell = stripwell
      @num_wells = num_wells
      @second_half = second_half
      @label = int_to_letter @@num_labels
      @@num_labels += 1
    end
    def stripwell
      @stripwell
    end
    def num_wells
      @num_wells
    end
    def second_half
      @second_half
    end
    def label
      @label
    end
    def reset
      @@num_labels = 0
    end
  end # Label

  def create_labels well_array
    # Create list of Labels
    last_stripwell = nil
    labels = well_array.map { |row|
      last_stripwell = nil
      row.each_with_index.map { |stripwell, column|
        if stripwell != last_stripwell
          last_stripwell = stripwell
          label_length = row.count { |s| s == stripwell }
          if label_length < stripwell.num_samples && column == 0 # This is the second half of a stripwell
            Label.new(stripwell, label_length, true)
          else
            Label.new(stripwell, label_length)
          end
        else
          nil
        end
      }.push(row.length < 12 ? Label.new(nil, 12 - row.length) : nil) # EB buffer
      .select { |s| s != nil }
    }.flatten
  end # create_analyzer_well_table

  def format_table well_array
    extend ColorGenerator
    extend RowNamer
    piece_index = 0 # The current stripwell piece (used for int_to_letter and cell color)
    well_array.each_with_index.map { |row, i|
      prev_stripwell = well_array[0][0] # The previous stripwell that was iterated over (for labeling)
      row.concat(Array.new(12 - row.length) { nil }).map { |stripwell|
        if stripwell != prev_stripwell
          prev_stripwell = stripwell
          piece_index += 1
        end
        { check: true, content: (int_to_letter piece_index), style: { background: (sample_color_gradient_default piece_index) } }
      }.unshift({ content: (row_name i), style: { background: "#DDD" } })
    }.unshift([""] + (1..12).to_a.map! { |x| { content: x, style: { background: "#DDD" } } })
    .concat(Array.new(8 - well_array.length) { |i| [{ content: (row_name (i + 2)), style: { background: "#DDD" } }] + Array.new(12) { { content: "", style: { background: "#EEE" } } } } )
  end # format_table

  def create_relabel_instructions labels, stripwell_cuts
    instructions = []
    labels.select{ |x| x.stripwell != nil }.each { |label|
      if !label.second_half
        well_to_label = 1.ordinalize
        instructions.append("Grab stripwell #{label.stripwell} (#{label.stripwell.num_samples} wells). Wipe off the current id. Label the #{well_to_label} well \"#{label.label}\".")
      else
        well_to_label = (stripwell_cuts["#{label.stripwell}"] + 1).ordinalize
        instructions[-1] += " Label the #{well_to_label} well \"#{label.label}\", and cut right before the label."
      end
    }
    instructions
  end # create_relabel_instructions
end # StripwellArrayOrganization