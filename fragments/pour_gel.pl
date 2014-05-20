require "aqualib:lib/util.pl"
require "aqualib:lib/cloning.pl"

argument
  FO: generic
end

fragments_per_gel = 10
num_fragments = length(FO[:fragments])
num_gels = ceil(num_fragments / fragments_per_gel)

print("Number of gels to pour",num_gels)

i=0
gels = []

while i<num_gels
  produce silently
    gel = 1 "Gel"
    data
      matrix: array_same(-1,12)
    end  
  end
  gels = append(gels,gel)
  i = i+1
end

print("Gel IDs",gels)
