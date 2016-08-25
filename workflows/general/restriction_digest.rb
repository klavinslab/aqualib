needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  def arguments
    {
      io_hash: {},
      template_ids: [],
      enzymes: [],
      band_lengths: []
    }
  end #arguments

  def main
    io_hash = input[:io_hash]
    io_hash = input if input[:io_hash].empty?
    io_hash = { debug_mode: "Yes", template_ids: [], enzymes: [], band_lengths: [], task_ids: [], group: "technicians"}.merge io_hash
    if io_hash[:debug_mode].downcase == "yes"
      def debug
        true
      end
    end

    show {
      note io_hash[:template_ids]
      note io_hash[:enzymes]
    }
    templates = io_hash[:template_ids].map { |tid| find(:item, id: tid[0]) }
    enzymes = io_hash[:enzymes].map { |eids| eids.map { |eid| find(:sample, id: eid)[0].in("Enzyme Stock") } }
    show {
      note templates
      note enzymes
    }

    ensure_stock_concentration templates

    stripwells = produce spread templates, "Stripwell", 1, 12
    show {
      title "Grab stripwell(s) for restriction digest"
      stripwells.each_with_index do |sw,idx|
        if idx < stripwells.length - 1
          check "Grab a stripwell with 12 wells, and label it #{sw.id}."
        else
          number_of_wells = plasmid_stocks.length - idx * 12
          check "Grab a stripwell with #{number_of_wells} wells, and label it #{sw.id}."
        end
      end
    }

    templates_with_volume = templates.map { |t| "#{(200.0 / t.datum[:concentration]).round(1)} µL of #{t.id}" }
    buffer_with_volume = templates.map { |t| "#{(200.0 / t.datum[:concentration]).round(1)} µL of #{t.id}" }
    enzymes_with_volume = templates.map { |t| "#{(200.0 / t.datum[:concentration]).round(1)} µL of #{t.id}" }
    water_with_volume = templates.map { |t| "#{(200.0 / t.datum[:concentration]).round(1)} µL of #{t.id}" }

    load_samples_variable_vol( ["Template"], [
      templates_with_volume,
      ], stripwells,
      { show_together: true, title_appended_text: "with Template" })
    load_samples_variable_vol( ["Template"], [
      templates_with_volume,
      ], stripwells,
      { show_together: true, title_appended_text: "with Template" })
    load_samples_variable_vol( ["Template"], [
      templates_with_volume,
      ], stripwells,
      { show_together: true, title_appended_text: "with Template" })
    load_samples_variable_vol( ["Template"], [
      templates_with_volume,
      ], stripwells,
      { show_together: true, title_appended_text: "with Template" })
  end
end