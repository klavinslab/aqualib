needs "aqualib/lib/cloning"

class Protocol

  include Cloning
  require 'matrix'

  def sort_by_location fragments
    fragments.sort! { |frag1, frag2|
      frag1.location <=> frag2.location
    }
  end # sort_by_location

  def arguments
    {
      io_hash: {},
      number_buffer_stocks: 2,
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

    buffer_stocks = Array.new(io_hash[:number_buffer_stocks]) { produce new_sample "5X ISO Buffer", of: "Enzyme Buffer", as: "Enzyme Buffer Stock" }

    show {
      title "Prepare tube"
      check "Take #{buffer_stocks.length} 1.5 mL tube#{buffer_stocks.length == 1 ? "" : "s"}."
      check "Label each tube with one of the following ids:"
      note buffer_stocks.collect { |stock| "#{stock}" }.join(", ")
      check "On the side of each tube, label \"5X ISO Buffer\" with your initials and the date."
    }

    show {
      title "Move to media bay"
    }

    peg = find(:item, object_type: { name: "PEG 8000" })[0]
    take [peg], interactive: true, method: "boxes"
    show {
      title "Add PEG-8000 to tube(s)"
      note "For each tube:"
      bullet "Take a piece of weigh paper and fold in half diagonally."
      warning "Wipe spatula with ethanol before and after using."
      bullet "Weigh out 0.25 g PEG-8000 using the weigh paper and scale."
      bullet "CAREFULLY pour PEG into 1.5 mL tube."
    }

    tris = find(:item, object_type: { name: "1M Tris-HCL, ph7.5" })[0]
    take [tris], interactive: true, method: "boxes"
    show {
      title "Add 1M Tris-HCL to tube(s)"
      note "Pipette out 500 uL of Tris HCl and carefully pipette on top of the PEG-8000 in the 1.5 mL tube(s)."
    }
    release [peg, tris], interactive: true, method: "boxes"

    liquid_reagents = ["2M MgCl2", "1M DTT", "100mM NAD", "100mM dGTP", "100mM dATP", "100mM dTTP", "100mM dCTP"]
    .collect { |reagent_name| find(:item, object_type: { name: reagent_name })[0] }
    sort_by_location liquid_reagents
    take liquid_reagents, interactive: true, method: "boxes"
    show {
      title "Thaw each aliquot"
      note "Wait until each aliquot taken from the freezer is thawed completely. Vortex periodically to speed up the thawing."
    }

    show {
      title "Add each aliquot to 1.5 mL tube(s)"
      note "Add each aliquot to 1.5 mL tube(s) according to the following table:"
      table [["Aliquot", "Volume (µL)"],
             ["1 M DTT", { check: true, content: 50 }],
             ["100 mM NAD", { check: true, content: 50 }],
             ["MgCl2", { check: true, content: 25 }],
             ["100 mM dGTP", { check: true, content: 10 }],
             ["100 mM dATP", { check: true, content: 10 }],
             ["100 mM dTTP", { check: true, content: 10 }],
             ["100 mM dCTP", { check: true, content: 10 }]]
    }

    show {
      title "Add molecular grade water to 1.5 mL tube(s) and mix"
      check "Add 100 uL MG H20 to 1.5 mL tube(s)."
      check "Vortex until all reagents are dissolved and homologous."
      warning "Due to the PEG-8000, this may take awhile."
    }
    release liquid_reagents, interactive: true, method: "boxes"

    release buffer_stocks, interactive: true, method: "boxes"

    return { io_hash: io_hash }
  end # main

end
