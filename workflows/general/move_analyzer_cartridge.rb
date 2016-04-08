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

    cartridge = find(:item, object_type: { name: "QX DNA Screening Cartridge" })[0]
    show {
      title "Prepare to insert QX DNA Screening Cartridge into the machine"
      warning "Please keep the cartridge vertical at all times!".upcase
      check "Take the cartridge from #{cartridge.location} and bring to fragment analyzer."
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
    }
    show {
      title "Wait 30 minutes for the cartridge to equilibrate"
      check "Start a <a href='https://www.google.com/search?q=30+minute+timer&oq=30+minute+timer&aqs=chrome..69i57j69i60.2120j0j7&sourceid=chrome&ie=UTF-8' target='_blank'>30-minute timer on Google</a>, and do not run the fragment analyzer until it finishes."
    }
    take [cartridge]
    cartridge.location = "Fragment analyzer"
    cartridge.save
    release [cartridge]

    return { io_hash: io_hash }
  end # main

end