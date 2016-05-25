needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  def arguments
    {
    }
  end

  def main
    plasmids = find(:sample, { sample_type: { name: "Plasmid" } })
    changes = []
    while changes.length < 10
      plasmids.each do |plasmid|
        primer_ids_str = plasmid.properties["Sequencing_primer_ids"]
        primer_ids = primer_ids_str.split(",").map { |s| s.to_i }
        if primer_ids.all? { |i| i != 0 }
          primers = primer_ids.collect { |id| find(:sample, id: id)[0] }
          plasmid.properties["Sequencing Primers"] = primers
          if plasmid.errors.empty?
            changes.push "plasmid sequencing primers changed to new format"
          end
        end
      end
    end
    show {
      note plasmids.length
      note changes.length
    }
    return changes
  end
end
