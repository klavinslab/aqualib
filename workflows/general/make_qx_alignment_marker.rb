needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  def arguments
    {
      io_hash: {},
      debug_mode: "Yes"
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

    stripwell_data = show {
      title "Prepare stripwell"
      check "Grab a new stripwell with 12 wells."
      check "Label stripwell with alignment marker size (i.e. 15 bp-5 kb)"
      check "Load 15 µL of QX Alignment Marker into each tube."
      check "Add 5 µL of QX Mineral Oil to each tube."
      note "Make sure to pipette against the wall of the tube."
      note "The oil layer should rest on top of the alignment marker layer."
      select ["Yes", "No"], var: "using_today", label: "Are you using this alignment marker today?", default: 0
    }
    alignment_marker_stripwell = produce spread(Array.new(12) { alignment_marker.sample }, "Stripwell", 1, 12)[0]

    if stripwell_data[:using_today] == "Yes"
      show {
        title "Place stripwell in buffer array"
        note "Move to the fragment analyzer."
        note "Open ScreenGel software."
        check "Click on the \"Load Position\" icon."
        check "Open the sample door and retrieve the buffer tray."
        check "Place the alignment marker stripwell in the MARKER 1 position of the buffer array."
        image "make_marker_placement"
        check "Place the buffer tray in the buffer tray holder"
        image "make_marker_tray_holder"
        check "Close the sample door."
      }
      alignment_marker_stripwell.location = "Fragment analyzer"
    else
      show {
        title "Cap the stripwell and store in SF2"
        check "Cap the stripwell."
        check "Store the stripwell in SF2."
      }
      alignment_marker_stripwell.location = "SF2"
    end
    alignment_marker_stripwell.save
    release [alignment_marker_stripwell]
    release [alignment_marker, mineral_oil], interactive: true

    return { io_hash: io_hash }
  end # main

end