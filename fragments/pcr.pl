require "aqualib:lib/util.pl"

function fragment_info(fid)

  local frag = find(:sample,{id: fid})
  local temp = find(:sample,{name: frag[:field3]})
  local fwds = find(:item,{ sample: { name: frag[:field4] }, object_type: { name: "Primer Aliquot" } } )
  local revs = find(:item,{ sample: { name: frag[:field4] }, object_type: { name: "Primer Aliquot" } } )

  if length(fwds) == 0 || length(revs) == 0 
   
    step 
      description: "Error"
      warning: "Primer stock(s) missing for fragment %{fid}"
    end

    stop

  end

  return {
    fragment_id: fid,
    fragment_name: frag[:name],
    template_id:   temp[:id],
    template_name: temp[:name],
    forward_primer_id:   fwds[0][:id],
    forward_primer_name: fwds[0][:name],
    reverse_primer_id:   fwds[0][:id],
    reverse_primer_name: fwds[0][:name]
  }

end

argument
  fragment_list: number array
end

FO = { fragments: [] }

foreach f in fragment_list
  FO[:fragments] = append(FO[:fragments], fragment_info(f))
end

print("Fragment Info", FO)

fwd = ha_select(FO[:fragments],:forward_primer_id)
rev = ha_select(FO[:fragments],:reverse_primer_id)

take
  primers = item concat(fwd,rev)
end

print("Primers",primers)

