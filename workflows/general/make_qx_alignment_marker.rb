needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  def arguments
    {
      io_hash: {},
      num_markers: 1,
      debug_mode: "No"
    }
  end

  def main
    io_hash = input[:io_hash]
    io_hash = input if input[:io_hash].empty?
    io_hash = { debug_mode: "No" }.merge io_hash
    debug_mode = false
    # re define the debug function based on the debug_mode input
    if io_hash[:debug_mode].downcase == "yes"
      def debug
        true
      end
      debug_mode = true
    end

    alignment_marker = find(:item, sample: { name: "QX Alignment Marker (15bp/5kb)" })[0]
    mineral_oil = find(:item, sample: { name: "QX Mineral Oil" })[0]
    take [alignment_marker, mineral_oil], interactive: true
    alignment_marker_stripwells = Array.new(io_hash[:num_markers]) { produce spread(Array.new(12) { alignment_marker.sample }, "Stripwell", 1, 12)[0] }

    stripwell_data = show {
      title "Prepare stripwell(s)"
      check "Grab #{io_hash[:num_markers]} 12-well stripwell(s)."
      check "Label stripwell(s) with alignment marker size (i.e. 15 bp-5 kb) and the following ids:"
      note alignment_marker_stripwells.map { |s| "#{s}" }.join(", ")
      check "Load 15 µL of QX Alignment Marker into each tube."
      check "Add 5 µL of QX Mineral Oil to each tube."
      note "Make sure to pipette against the wall of the tubes."
      note "The oil layer should rest on top of the alignment marker layer."
    }

    marker_in_analyzer = find(:item, object_type: { name: "Stripwell" })
                            .find { |s| s.datum[:matrix][0][0] == alignment_marker.sample.id &&
                                        s.location == "Fragment analyzer" }
    marker_needs_replacing = marker_in_analyzer.datum[:begin_date] ? Date.today - (Date.parse marker_in_analyzer.datum[:begin_date]) >= 5 : true
    if marker_needs_replacing
      show {
        title "Place stripwell #{alignment_marker_stripwells[0]} in buffer array"
        note "Move to the fragment analyzer."
        note "Open ScreenGel software."
        check "Click on the \"Load Position\" icon."
        check "Open the sample door and retrieve the buffer tray."
        check "Discard the current alignment marker stripwell (labeled #{marker_in_analyzer})."
        check "Place the alignment marker stripwell labeled #{alignment_marker_stripwells[0]} in the MARKER 1 position of the buffer array."
        image "make_marker_placement"
        check "Place the buffer tray in the buffer tray holder"
        image "make_marker_tray_holder"
        check "Close the sample door."
      }
      alignment_marker_stripwells[0].location = "Fragment analyzer"
      alignment_marker_stripwells[0].datum = alignment_marker_stripwells[0].datum.merge({ begin_date: Date.today.strftime })
      alignment_marker_stripwells[0].save
      release [alignment_marker_stripwells[0]]
      delete marker_in_analyzer
      alignment_marker_stripwells.delete alignment_marker_stripwells[0]
    end
    if alignment_marker_stripwells.any?
      show {
        title "Cap the stripwell(s) and store in SF2"
        check "Cap the stripwell(s) labeled with the following ids:"
        note alignment_marker_stripwells.map { |s| "#{s}" }.join(", ")
        check "Store the stripwell(s) in SF2."
      }
      alignment_marker_stripwells.each { |s| s.location = "SF2"
                                             s.save }
      release alignment_marker_stripwells
    end

    release [alignment_marker, mineral_oil], interactive: true

    return { io_hash: io_hash }
  end # main

end