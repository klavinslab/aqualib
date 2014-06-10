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
  # TODO REMOVE CLEAR
  foreach i in range(12)
    col_set(g,0,i,-1)
  end
  col_set(g,0,0,ladder_sample_id)
  col_set(g,0,6,ladder_sample_id)
end

t = col_transfer ( FO[:stripwells], FO[:gels] )

step
  note: "Transfer PCR products from stripwells into the gels according the the table below."
  table: t
  table: concat( 
     [ [ "Stripwell", "Row", "Column", "Gel", "Row", "Lane" ] ],
     t )
end

release concat(concat(stripwells,gels),ladder)

log
  return: { FO: FO }
end
