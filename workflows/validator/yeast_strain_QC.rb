class Validator

  def check task
    t = task
    length_check = t.simple_spec[:yeast_plate_ids].length == t.simple_spec[:num_colonies].length
    t.notify "yeast_plate_ids need to have the same array length with num_colonies.", job_id: jid if !length_check
    t[:yeast_plate_ids] = { ready_to_QC: [], not_ready_to_QC: [] }
    t.simple_spec[:yeast_plate_ids].each_with_index do |yid, idx|
      primer1 = find(:item, id: yid)[0].sample.properties["QC Primer1"].in("Primer Aliquot")[0]
      primer2 = find(:item, id: yid)[0].sample.properties["QC Primer2"].in("Primer Aliquot")[0]
      if primer1 && primer2 && (t.simple_spec[:num_colonies][idx] || 0).between?(0, 10)
        t[:yeast_plate_ids][:ready_to_QC].push yid
      else
        t[:yeast_plate_ids][:not_ready_to_QC].push yid
        t.notify "QC Primer 1 for yeast plate #{yid} does not have any primer aliquot.", job_id: jid if !primer1
        t.notify "QC Primer 2 for yeast plate #{yid} does not have any primer aliquot.", job_id: jid if !primer2
        t.notify "num_colonies for yeast plate #{yid} need to be a number between 0,10", job_id: jid if !(t.simple_spec[:num_colonies][idx] || 0).between?(0, 10)
      end
    end
    ready_conditions = length_check && t[:yeast_plate_ids][:ready_to_QC].length == t.simple_spec[:yeast_plate_ids].length

    if ready_conditions
      set_task_status(t, "ready") if t.status != "ready"
      t.save
    else
      set_task_status(t, "waiting") if t.status != "waiting"
      t.save
    end

  end

end