require "lib/util.pl"

information "Use this protocol to rehydrate any number of lyophilized primers that have just been received. 
             A primer stock and an initial primer aliquot will be made."

more_primers = "Yes"
primers = []
te = []
descriptions = []

while more_primers == "Yes"

  step
     description: "Enter a primer id and quantity."
     getdata
       id: number, "Primer Id (Written on Tube)"
       mass: number, "Enter the number of nanomoles (nm) of DNA in the tube"
     end
  end

  primer_info = find(:sample,{id: id})[0]

  if primer_info != [] && primer_info[:sample_type][:name] == "Primer"

    primers = append(primers,primer_info)
    te = append(te,10*mass)

    step
      description: "Found " + primer_info[:name] + " for project " + primer_info[:project]
      foreach p in primers
        note: to_string(p[:id]) + ": " + p[:name]
      end
      getdata
        more_primers: string, "Enter more primer ids?", [ "Yes", "No" ]
      end
    end

  else

    step
      description: "Could not find a primer with id " + to_string(id) + " in the database."
      note: "Click next to try again."
    end

  end

end

stocks = produce_multiple("Primer Stock", ha_select(primers,:name))
aliquots = produce_multiple("Primer Aliquot", ha_select(primers,:name))

n = 0

step
  description: "Label tubes"
  table: concat(
    [ [ "Primer Number", "Primer Name", "Primer Stock Item Number", "Primer Aliquot Item Number" ] ],
    transpose([
      ha_select(primers,:id),
      ha_select(primers,:name),
      ha_select(stocks,:id),
      ha_select(aliquots,:id)
    ])
  )
  bullet: "Label each primer tube with the Primer Stock Item Number listed above."
  bullet: "For each primer, label a new 1.5 mL tube with the Primer Aliquot Item Number listed above."
  warning: "Primer tubes will now be refered to by their item numbers, not their sample numbers."
end

step
  description: "Rehydrate the primer DNA to make stocks"
  table: concat(
    [ [ "Primer Stock Tube", "Amount of TE (&micro;L)" ] ],
    transpose([
      ha_select(stocks,:id),
      te
    ])
  )
  bullet: "Spin each tube for 10 seconds."
  bullet: "Transfer TE to the tube."
  bullet: "Vortex tube for 20 seconds to mix and and then spin it down for 10 seconds."
end

step
  description: "Make first aliquots"
  table: concat(
    [ [ "Primer Aliquot Tube", "Primer Stock", "Amount of primer stock (&micro;L)", "Amount of TE (&micro;L)" ] ],
    transpose([
      ha_select(aliquots,:id),
      ha_select(stocks,:id),
      array_same ( 10, length(primers) ),
      array_same ( 90, length(primers) )
    ])
  )
end

step
  description: "Store sample items."
  table: concat(
    [ [ "Item Id", "Location" ] ],
    transpose([ 
      concat(ha_select(stocks,:id),ha_select(aliquots,:id)), 
      concat(ha_select(stocks,:location),ha_select(aliquots,:location)) 
    ])
  )
end
