class Validator

  def check task
    t = task
    errors = [] # an array to store errors
    length_check = t.simple_spec[:yeast_plate_ids].length == t.simple_spec[:num_colonies].length
    errors.push "yeast_plate_ids need to have the same array length with num_colonies." if !length_check
    t[:yeast_plate_ids] = { ready_to_QC: [], not_ready_to_QC: [] }
    t.simple_spec[:yeast_plate_ids].each_with_index do |yid, idx|
      primer1 = find(:item, id: yid)[0].sample.properties["QC Primer1"].in("Primer Aliquot")[0]
      primer2 = find(:item, id: yid)[0].sample.properties["QC Primer2"].in("Primer Aliquot")[0]
      if primer1 && primer2 && (t.simple_spec[:num_colonies][idx] || 0).between?(0, 10)
        t[:yeast_plate_ids][:ready_to_QC].push yid
      else
        t[:yeast_plate_ids][:not_ready_to_QC].push yid
        errors.push "QC Primer 1 for yeast plate #{yid} does not have any primer aliquot." if !primer1
        errors.push "QC Primer 2 for yeast plate #{yid} does not have any primer aliquot." if !primer2
        errors.push "num_colonies for yeast plate #{yid} need to be a number between 0,10" if !(t.simple_spec[:num_colonies][idx] || 0).between?(0, 10)
      end
    end

    ready_conditions = length_check && t[:yeast_plate_ids][:ready_to_QC].length == t.simple_spec[:yeast_plate_ids].length

    if ready_conditions
      return true
    else
      return errors
    end

  end

end