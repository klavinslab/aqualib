require "aqualib:lib/util.pl"
require "aqualib:lib/cloning.pl"

argument
  FO: generic
end

fragments_per_gel = 10.0
num_fragments = length(FO[:fragments])
num_gels = ceil(num_fragments / fragments_per_gel)

i=0
gels = []

while i<num_gels
  gels = append(gels,new_gel())
  i = i+1
end

FO[:gels] = ha_select(gels,:id)

print("Pour %{num_gels} gel(s)","Label it(them) with the item number(s) " + to_string(FO[:gels]))

log
  return: { FO: FO }
end

