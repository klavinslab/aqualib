require "aqualib:lib/util.pl"
require "aqualib:lib/cloning.pl"

fragment_list = [ 21, 22, 23, 24, 25, 26, 27, 28, 72, 73, 120, 121, 122, 123, 124, 125, 126, 127, 128 ]

######################################################################################
# make fragement object
#

FO = { fragments: [], stripwells: [], errors: [] }

foreach f in fragment_list
  info = fragment_info(f)
  if info[:error]
    FO[:errors] = append(FO[:errors], info[:error])
  else
    FO[:fragments] = append(FO[:fragments], info)
  end
end

if length(FO[:errors]) > 0 

  step
    description: "Some fragments will be skipped."
    foreach e in FO[:errors]
      warning: e
    end
    note: "Number of fragments requested: " + to_string(length(fragment_list))
    note: "Number fragments to be built: " + to_string(length(FO[:fragments]))
  end

end

template = ha_select(FO[:fragments],:template_id)
fwd = ha_select(FO[:fragments],:forward_primer_id)
rev = ha_select(FO[:fragments],:reverse_primer_id)

######################################################################################
# take primers
#

take
  templates_and_primers = item unique(concat(template,concat(fwd,rev)))
end

######################################################################################
# take reagents
#

  # TODO

######################################################################################
# produce stripwell (may need to make multiple stripwells)
#

num_stripwells = ceil( length(FO[:fragments]) / 12.0)

i=0
stripwells = []

while i < num_stripwells

  produce silently
    stripwell = 1 "Stripwell"
    data
      matrix: [ take(fragment_list,12*i,12) ]
    end
  end

  stripwells = append ( stripwells, stripwell[:id] )

  i = i + 1

end

FO[:stripwells] = stripwells

######################################################################################
# set up reactions
#

  # TODO

i=0
while i < num_stripwells

  frags = take(FO[:fragments],12*i,12)

  step
    description: "Prepare stripwell no. " + to_string(i+1)
    note: "Label a new stripwell with the the item number " + to_string(stripwells[i])
    check: "TODO: Add reagents"
    table: concat(
      [ [ "Well", "Template", "Forward Primer", "Reverse Primer" ] ],
      transpose([
        range(1,length(frags),1),
        ha_select(frags,:template_id),
        ha_select(frags,:forward_primer_id),
        ha_select(frags,:reverse_primer_id)
      ] ) )
  end

  i = i+1

end


######################################################################################
# put stripwell in thermocycler
#

  # TODO (may want to ask technician which thermocycler was used)

######################################################################################
# return everything
#

release(templates_and_primers)

log
  return: { FO: FO }
end

