require "aqualib:lib/util.pl"
require "aqualib:lib/cloning.pl"

fragment_list = [ 21, 22 ]

######################################################################################
# make fragement object
#

FO = { fragments: [], stripwells: [] }

foreach f in fragment_list
  FO[:fragments] = append(FO[:fragments], fragment_info(f))
end

tem = ha_select(FO[:fragments],:template_id)
fwd = ha_select(FO[:fragments],:forward_primer_id)
rev = ha_select(FO[:fragments],:reverse_primer_id)

######################################################################################
# take primers
#

take
  templates_and_primers = item unique(concat(tem,concat(fwd,rev)))
end

######################################################################################
# take reagents
#

  # TODO

######################################################################################
# produce stripwell (may need to make multiple stripwells)
#

  # TODO: Produce num_fragments / 12 stripwells

produce silently
  stripwell = 1 "Stripwell"
  data
    matrix: [ fragment_list ]
  end
end

FO[:stripwells] = [ stripwell ]

######################################################################################
# set up reactions
#

  # TODO

swid = stripwell[:id]

step
  description: "Label the a new stripwell %{swid} and set up reactions"
end

######################################################################################
# put stripwell in thermocycler
#

  # TODO (may want to ask technician which thermocycler was used)

step
  description: "Put stripwell %{swid} in the Thermocycler"
end

######################################################################################
# return everything
#

release(templates_and_primers)

log
  return: { FO: FO }
end

