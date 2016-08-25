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

    show {
      note io_hash[:template_ids]
      note io_hash[:template_ids].size
      note io_hash[:enzymes]
      note io_hash[:enzymes].size
    }
    templates = io_hash[:template_ids].map { |tid| find(:item, id: tid)[0] }
    enzymes = io_hash[:enzymes].map { |eids| eids.map { |eid| find(:sample, id: eid)[0].in("Enzyme Stock")[0] } }
    buffer = find(:sample, name: "Cut Smart")[0].in("Enzyme Buffer Stock")[0]
    show {
      note templates
      note templates.size
      note enzymes
      note enzymes.size
      note buffer
    }

    take templates + enzymes.flatten + [buffer], interactive: true, method: "boxes"

    ensure_stock_concentration templates

    stripwells = produce spread templates, "Stripwell", 1, 12
    show {
      title "Grab stripwell(s) for restriction digest"
      stripwells.each_with_index do |sw,idx|
        if idx < stripwells.length - 1
          check "Grab a stripwell with 12 wells, and label it #{sw.id}."
        else
          number_of_wells = templates.length - idx * 12
          check "Grab a stripwell with #{number_of_wells} wells, and label it #{sw.id}."
        end
      end
    }

    template_vols = templates.map { |t| (200.0 / t.datum[:concentration]).round(1) }
    water_vols = template_vols.map.with_index { |tv| 10 - tv - 1 - 0.5 * enzymes[idx].length }

    templates_with_volume = templates.map.with_index { |t, idx| "#{template_vols[idx]} µL of #{t.id}" }
    buffer_with_volume = templates.map { |t| "1 µL of #{buffer.id}" }
    enzymes_with_volume = enzymes.map { |es| es.map { |e| "0.5 µL of #{e.id}" } }
    water_with_volume = water_vols.map { |wv| "#{wv} µL" }

    load_samples_variable_vol( ["Template"], [
      templates_with_volume,
      ], stripwells,
      { show_together: true, title_appended_text: "with Template" })
    load_samples_variable_vol( ["Cut Smart Buffer"], [
      buffer_with_volume,
      ], stripwells,
      { show_together: true, title_appended_text: "with Cut Smart Buffer" })
    load_samples_variable_vol( ["Enzyme"],
      enzymes_with_volume,
      stripwells,
      { show_together: true, title_appended_text: "with Enzyme" })
    load_samples_variable_vol( ["Molecular Grade Water"], [
      water_with_volume,
      ], stripwells,
      { show_together: true, title_appended_text: "with Molecular Grade Water" })

    stripwells.each { |sw| sw.location = "37 C standing incubator" }

    release stripwells + templates + enzymes.flatten + [buffer], interactive: true, method: "boxes"
  end
end