class Protocol

  def main

    #####################################################################
    # Test 'distribute', which creates items from a collection
    # that should be put in locations using a wizard. The distribute function
    # calls Item.make, which calls the location wizard.

    samples = find(:sample,sample_type: {name: 'Fragment'})
    col = (produce spread samples[0,12], "Stripwell", 1, 12)[0]
    parts = distribute( col, "Fragment Stock", interactive: false )
    take parts

    show {
      title "Test: 'distribute'"
      note "Collection"
      table col.matrix
      note "Item locations, should have the form 'M20.x.y.z'"
      table parts.collect { |p| [ p.id, p.location ] }
      note "Check associations to make sure a freezer box is shown for each item."
    }

    release [col]

    ##########################################################################
    # Test 'take' (and 'release') which should show item locations properly
    #

    take( parts, interactive: true) { 
      title "Test: take"
      note "Item locations should display properly"
    }
    release parts

    ###########################################################################
    # Test boxes method for take, which should show where the items are in
    # the freezer.
    #

    take parts, interactive: true, method: 'boxes'
    release parts

  end

end
