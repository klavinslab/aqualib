require "aqualib:lib/util.pl"
require "aqualib:lib/cloning.pl"

function gelpos(stripwell_no,well_no,gels)

  local n = 12*stripwell_no + well_no
  local gel = floor(n/10.0)
  local pos = mod(n,10) + 1
  local adjusted_pos = 0

  if pos <= 5
    return [ well_no+1, gels[gel][:id], pos+2 ]
  else
    return [ well_no+1, gels[gel][:id], pos+2 ]
  end

end

function map_stripwell_to_gel(num, row,gels)
  
  local i = 0
  local result = []

  while i < length(row)
    result = append(result,gelpos(num,i,gels))    
    i = i+1
  end

  return result

end

argument
  FO: generic
end

take
  stripwells = item FO[:stripwells]
  gels = item FO[:gels]
end

step
   description: "Add ladder to gels"
   foreach gid in FO[:gels]
     note: "Put 10 &micro;L of ladder to the first and seventh wells of gel %{gid}"
   end
end

print("Stripwells",stripwells)

i=0
while i < length(stripwells)

  transfer = map_stripwell_to_gel(i,stripwells[i][:data][:matrix][0],gels)

  step
    table: concat(
      [ [ "Well Number of Stripwell " + to_string(stripwells[i][:id]), "Gel ID", "Lane No." ] ],
      transfer
    )
  end
  i = i+1

end

log
  return: { FO: FO }
end
