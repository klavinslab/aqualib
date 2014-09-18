needs "aqualib/lib/standard"

class Protocol

  def arguments
    { volumes: "Media volume(s) in mL: 200, 400, or 800",
      add_agar: "Make agar media? (yes or no)"}
  end

  def main
    volumes = input["volumes"]
    add_agar = input["add_agar"]

    # If argument for volume was bad, catch it - unnecessary?
    volumes.map! { |v|
      if v != 200 && v != 400 && v != 800
        show {
          title "Volume was incorrectly entered as %{v}"
          note "Enter your best guess of the correct volume from the options below."
          select [200, 400, 800], var: "new_v", label: "Select a volume in mL."
        }
        new_v
      else
        v
      end
    }

    # Input validation on adding agar
    if add_agar != "Yes" && add_agar != "No"
      show {
        title "The question of whether this is to be agar media was incorrectly entered as %{add_agar}."
        note "You can only specify Yes or No! Hassle the person who scheduled this protocol."
        select ["Yes", "No"], var: "add_agar", label: "Add agar?"
      }
    end

    if add_agar == "Yes"
      lb_powder = choose_object "LB Agar Miller"
    else
      lb_powder = choose_object "Difco LB Broth, Miller"
    end

    bottle_infos = []
    bottles = []
    stir_bars = []
    volumes.each do |v|
      lb_agar_grams_for_800 = 29.6
      lb_grams_for_800 = 20.0
      # Construct a hash containing useful bottle info
      bottle_info = {}
      if v == 200
        bottle_info[:bottle] = "250 mL Bottle"
      elsif v == 400
        bottle_info[:bottle] = "500 mL Bottle"
      elsif v == 800
        bottle_info[:bottle] = "1 L Bottle"
      end

      if add_agar == "Yes"
        bottle_info[:grams] = lb_agar_grams_for_800 / (800.0 / v)
        bottle_info[:name] = "%{v} mL LB Agar (unsterile)"
      else
        bottle_info[:grams] = lb_grams_for_800 / (800.0 / v)
        bottle_info[:name] = "%{v} mL LB Liquid (unsterile)"
      end

      bottle_infos.push(bottle_info)

      # TODO: Figure out most convenient way to take the bottles. Bottles
      # are currently taken one at a time, which is slow since usually
      # more than one batch is being made.
      # Should just add n keyword argument to choose_object()? Interface?
      # TODO: Same for stir bars
      bottle = choose_object bottle_info
      bottles.push(bottle)
      if v == 800
        stir_bar = choose_object "Medium Magnetic Stir Bar"
        stir_bars.push(stir_bar)
      end

    end

    v.each_with_index do |v, i|
      add_dry_reagent("bottle %{i + 1}", bottle_info[:name], bottle_info[:grams])
      clean_spatula
    end

    v.each_with_index do |v, i|
      show {
        title "Add deionized water"
        note "Fill bottle %{i + 1} to the %{v} mL mark with deionized water."
      }
    end

  if add_agar == "Yes"
    show {
      title "Cap and mix."
      note "Tightly close the caps on each bottle and shake until all contents are dissolved. To check for dissolution, let bottle rest for 10 seconds, and then pick up and look for sediment on the bottom. This should take approximately 60 seconds."
    }
  else
    show {
      title "Cap and mix."
      note "Tightly close the caps on each bottle and shake until all contents are dissolved. To check for dissolution, let bottle rest for 10 seconds, and then pick up and look for sediment on the bottom. This should take approximately 20 seconds."
    }
  end

  # FIXME: this is surely the wrong way to do it in ruby
  # Use bottle_infos?
  v.each_with_index do |v, i|
    # TODO: A 'show' for producing objects - previous 'note', 'location'
    # functionality is gone?
    produce new_object bottle_infos[i][:name]
  end

  # TODO: Should do a produce-from here as bottles and stir bars go into
  # final product. Is this more than a silent release?
  # should treat quantity field as data field that can be messed with -
  # or come up with way to avoid having quantities at all
  # think about options - a quantity_take (or qtake) may work
  if stir_bars.length > 0
    release stir_bars
  end
  release bottles

  release lb

end
