require "aqualib:lib/util.pl"
require "aqualib:lib/cloning.pl"

#######################################################################################
# RUN GEL:
#

argument
  FO: generic
end

ladders = find(:item,{sample: { name: "1 kb Ladder" }, object_type: { name: "Ladder Aliquot" } })

if length(ladders) == 0
  die("No 1kb Ladder Available")
end

ladder_item_id = ladders[0][:id]
ladder_sample_id = ladders[0][:sample][:id]

take
  stripwells = item FO[:stripwells]
  gels = item FO[:gels]
  ladder = item ladder_item_id
end

step
   description: "Add ladder to gels"
   foreach gid in FO[:gels]
     note: "Put 10 &micro;L of ladder to the first and seventh wells of gel %{gid}"
   end
end

foreach g in FO[:gels]

  # TODO REMOVE THIS CLEAR -- it's only here so I can test this protocol over and over
  # foreach i in range(0,11,1)
  #   col_set(g,0,i,-1)
  # end

  col_set(g,0,0,ladder_sample_id)
  col_set(g,0,6,ladder_sample_id)

end

t = col_transfer ( FO[:stripwells], FO[:gels] )
t_clean = drop_column(drop_column(t,4),1)

i = 0

while i < length(t_clean)

  msg = "Transfer PCR products from the stripwells into the gels according the the table below."

  if i != 0
    msg = "Continue to transfer PCR products into the gels."
  end

  step

    description: "Load gel(s)"

    note: msg

    table: concat( 
       [ [ "Stripwell", "Well", "Gel", "Lane" ] ],
       take(t_clean,i,10) )

  end

  i = i + 10

end

release concat(concat(stripwells,gels),ladder)

log
  return: { FO: FO }
end
