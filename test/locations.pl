argument
    ids: sample("Plasmid") array, "Plasmids"
end


#############################################################
# Test produce
#

produce
    q = 1 "Plasmid Stock" of "pMOD-HOKan-pGRR-W10-RGR-W19"
end

step
  description: "q has location " + q[:location]
end

release [q]


#############################################################
# Test take
#

take
  items = item ids
end

step
  description: "Items"
  table: [ items ]
end

#############################################################
# Test modify
#

modify 
    items[0]
    location: "M20.5.4.4"
end

step
  description: "Check that location of item has changed."
end

modify 
    items[0]
    location: "M20.4.14.4"
end

step
  description: "Check that location of item has changed."
end

#############################################################
# Test release
#

release items


