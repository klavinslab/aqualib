needs "aqualib/lib/cloning"

class Protocol

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
    io_hash = { debug_mode: "No", gel_band_verify: "No", yeast_plate_ids: [], task_ids: [] }.merge io_hash
    debug_mode = false
    # re define the debug function based on the debug_mode input
    if io_hash[:debug_mode].downcase == "yes"
      def debug
        true
      end
      debug_mode = true
    end

    # Move cartridge
    cartridge = find(:item, object_type: { name: "QX DNA Screening Cartridge" })[0]
    show {
      title "Prepare to insert QX DNA Screening Cartridge into the machine"
      warning "Please keep the cartridge vertical at all times!".upcase
      check "Take the cartridge labeled #{cartridge} from #{cartridge.location} and bring to fragment analyzer."
      check "Remove the cartridge from its packaging and CAREFULLY wipe off any soft tissue debris from the capillary tips using a soft tissue."
      check "Remove the purge cap seal from the back of the cartridge."
      image "frag_an_cartridge_seal_off"
      warning "Do not set down the cartridge when you proceed to the next step."
    }
    show {
      title "Insert QX DNA Screening Cartridge into the machine"
      check "Use a soft tissue to wipe off any gel that may have leaked from the purge port."
      check "Open the cartridge compartment by gently pressing on the door."
      check "Carefully place the cartridge into the fragment analyzer; cartridge description label should face the front and the purge port should face the back of the fragment analyzer."
      check "Insert the smart key into the smart key socket; key can be inserted in either direction."
      image "frag_an_cartridge_and_key"
      check "Close the cartridge compartment door."
      check "Open the ScreenGel software and latch the cartridge by clicking on the \"Latch\" icon."
      check "Grab the purge port seal bag from the bottom drawer beneath the machine, put the seal back on its backing, and return it in the bag to the drawer."
    }
    show {
      title "Wait 30 minutes for the cartridge to equilibrate"
      check "Start a <a href='https://www.google.com/search?q=30+minute+timer&oq=30+minute+timer&aqs=chrome..69i57j69i60.2120j0j7&sourceid=chrome&ie=UTF-8' target='_blank'>30-minute timer on Google</a>, and do not run the fragment analyzer until it finishes."
    }
    take [cartridge]
    cartridge.location = "Fragment analyzer"
    cartridge.save
    release [cartridge]

    # Replace alignment marker if necessary
    alignment_marker = find(:item, sample: { name: "QX Alignment Marker (15bp/5kb)" })[0]
    marker_in_analyzer = find(:item, object_type: { name: "Stripwell" })
                            .find { |s| s.datum[:matrix][0][0] == alignment_marker.sample.id &&
                                        s.location == "Fragment analyzer" }
    marker_needs_replacing = marker_in_analyzer.datum[:begin_date] ? Date.today - (Date.parse marker_in_analyzer.datum[:begin_date]) >= 7 : true
    alignment_marker_stripwell = find(:item, object_type: { name: "Stripwell" })
                                  .find { |s| s.datum[:matrix][0][0] == alignment_marker.sample.id &&
                                              s != marker_in_analyzer }
    if marker_needs_replacing && alignment_marker_stripwell
      show {
        title "Place stripwell #{alignment_marker_stripwell} in buffer array"
        note "Move to the fragment analyzer."
        note "Open ScreenGel software."
        check "Click on the \"Load Position\" icon."
        check "Open the sample door and retrieve the buffer tray."
        warning "Be VERY careful while handling the buffer tray! Buffers can spill."
        check "Discard the current alignment marker stripwell (labeled #{marker_in_analyzer})."
        check "Place the alignment marker stripwell labeled #{alignment_marker_stripwell} in the MARKER 1 position of the buffer array."
        image "make_marker_placement"
        check "Place the buffer tray in the buffer tray holder"
        image "make_marker_tray_holder"
        check "Close the sample door."
      }
      alignment_marker_stripwell.location = "Fragment analyzer"
      alignment_marker_stripwell.datum = alignment_marker_stripwell.datum.merge({ begin_date: Date.today.strftime })
      alignment_marker_stripwell.save
      release [alignment_marker_stripwell]
      delete marker_in_analyzer
    end

    return { io_hash: io_hash }
  end # main

end