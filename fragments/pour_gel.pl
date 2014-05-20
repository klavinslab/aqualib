require "aqualib:lib/util.pl"
require "aqualib:lib/cloning.pl"

argument
  FO: generic
end

fragments_per_gel = 10.0
num_fragments = length(FO[:fragments])
num_gels = ceil(num_fragments / fragments_per_gel)

print("Number of gels to pour",[fragments_per_gel,num_fragments,num_gels])

i=0
gels = []

while i<num_gels
  gels = append(gels,new_gel())
  i = i+1
end

print("Gel IDs",gels)
