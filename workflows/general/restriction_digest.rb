needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  def arguments
    {
      io_hash: {},
      template_ids: [70478, 70675],
      enzymes: [[51],[51,256]],
      band_lengths: [[54321, 12543], [12345]],
      debug_mode: "no"
    }
  end #arguments

  def main
    io_hash = input[:io_hash]
    io_hash = input if input[:io_hash].empty?
    io_hash = { debug_mode: "Yes", template_ids: [], enzymes: [[]], band_lengths: [[]], task_ids: [], group: "technicians" }.merge io_hash
    if io_hash[:debug_mode].downcase == "yes"
      def debug
        true
      end
    end

    templates = io_hash[:template_ids].map { |tid| find(:item, id: tid)[0] }
    enzymes = io_hash[:enzymes].map { |eids| eids.map { |eid| find(:sample, id: eid)[0].in("Enzyme Stock")[0] } }
    buffer = find(:sample, name: "Cut Smart")[0].in("Enzyme Buffer Stock")[0]

    take templates + [buffer], interactive: true, method: "boxes"
    ensure_stock_concentration templates

    show {
      title "Keep enzymes on ice block"
      warning "Grab an ice block, and place the enzymes on it while performing the following step!"
    }

    take enzymes.flatten, interactive: true, method: "boxes"

    stripwells = produce spread templates.map { |t| t.sample }, "Stripwell", 1, 12
    show {
      title "Grab stripwell(s) for restriction digest"
      stripwells.each_with_index do |sw, idx|
        if idx < stripwells.length - 1
          check "Grab a stripwell with 12 wells, and label it #{sw}."
        else
          number_of_wells = templates.length - idx * 12
          check "Grab a stripwell with #{number_of_wells} wells, and label it #{sw}."
        end

        task_id_mapping = io_hash[:task_ids][(idx * 12)...(sw.num_samples + idx * 12)]
        sw.datum = sw.datum.merge({ task_id_mapping: task_id_mapping })
      end
    }

    template_vols = templates.map { |t| (300.0 / t.datum[:concentration]).round(1) }
    water_vols = template_vols.map.with_index { |tv, idx| [(10 - tv - 1 - 0.5 * enzymes[idx].length).round(1), 0].max }
show {
  note template_vols
}
    templates_with_volume = templates.map.with_index { |t, idx| "#{template_vols[idx]} µL of #{t.id}" }
    buffer_with_volume = templates.map { |t| "1 µL of #{buffer.id}" }
    enzymes_with_volume = enzymes.map { |es| "0.5 µL#{es.length > 1 ? " each" : ""} of #{es.map { |e| "#{e.id}" }.join(" and ") }" }
    water_with_volume = water_vols.map { |wv| "#{wv} µL" }

    load_samples_variable_vol( ["Template"], [
      templates_with_volume,
      ], stripwells,
      { show_together: true, title_appended_text: "with Templates" }) {
      warning "Use a P2 for volumes smaller than 0.4 µL." if template_vols.any? { |tv| tv < 0.4 }
    }
    load_samples_variable_vol( ["Cut Smart Buffer"], [
      buffer_with_volume,
      ], stripwells,
      { show_together: true, title_appended_text: "with Cut Smart Buffer" })
    load_samples_variable_vol( ["Enzyme"], [
      enzymes_with_volume,
      ], stripwells,
      { show_together: true, title_appended_text: "with Enzymes" })
    load_samples_variable_vol( ["Molecular Grade Water"], [
      water_with_volume,
      ], stripwells,
      { show_together: true, title_appended_text: "with Molecular Grade Water" }) {
      warning "Use a P2 for volumes smaller than 0.4 µL." if water_vols.any? { |tv| tv < 0.4 }
      warning "Cap the stripwells after pipetting!"
    }

    stripwells.each { |sw| sw.location = "37 C standing incubator" }

    release stripwells + templates + enzymes.flatten + [buffer], interactive: true, method: "boxes"

    show {
      title "Start incubation timer"
      check "<a href='https://www.google.com/webhp?sourceid=chrome-instant&ion=1&espv=2&ie=UTF-8#q=one%20hour%20timer' target='_blank'>Click here</a> to start a one-hour timer."
      check "After one hour, the next protocol, move_to_fridge, will be ready."
    }

    if io_hash[:task_ids]
      io_hash[:task_ids].each do |tid|
        task = find(:task, id: tid)[0]
        set_task_status(task, "digested")
      end
    end

    io_hash[:stripwell_ids] = stripwells.map { |sw| sw.id }
    return { io_hash: io_hash }
  end
end