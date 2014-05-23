require "aqualib:lib/util.pl"
require "aqualib:lib/cloning.pl"

fragment_list = [ 21, 22, 23, 24, 25, 26, 27, 28, 72, 73, 120, 121, 122, 123, 124 ]

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

step
 note: template
 note: fwd
 note: rev
 note: unique(concat(template,concat(fwd,rev)))
end

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

  # TODO: Produce num_fragments / 12 stripwells

num_stripwells = ceil( length(FO[:fragments]) / 12.0)

i=0
stripwells = []

print("Number of stripwells",num_stripwells)

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

step
  description: "Label new stripwells %{stripwells} and set up reactions"
end

######################################################################################
# put stripwell in thermocycler
#

  # TODO (may want to ask technician which thermocycler was used)

step
  description: "Put stripwells %{stripwells} in the Thermocycler"
end

######################################################################################
# return everything
#

release(templates_and_primers)

log
  return: { FO: FO }
end

