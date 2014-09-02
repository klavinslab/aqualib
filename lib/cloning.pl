function fragment_info(fid)

  # Gets information about a fragment, including its name, template info, and primer info

  local frag = find(:sample,{id: fid})

  if frag == [] || frag[0][:sample_type][:name] != "Fragment"
    return { error: "Could not find fragment with id ${fid}" }
  end

  local temp = find(:item,{ sample: { name: frag[0][:field3]},  object_type: { name: "Plasmid Stock" }  } ).reject { |i| i.location == 'deleted '}
  local fwds = find(:item,{ sample: { name: frag[0][:field4] }, object_type: { name: "Primer Aliquot" } } ).reject { |i| i.location == 'deleted '}
  local revs = find(:item,{ sample: { name: frag[0][:field5] }, object_type: { name: "Primer Aliquot" } } ).reject { |i| i.location == 'deleted '}

  if length(temp) == 0 
    return { error: "Template stock(s) " + frag[0][:field3] +  " missing for fragment %{fid}." }
  end

  if length(fwds) == 0 
    return { error: "Forward primer stock(s) " + frag[0][:field4] + " missing for fragment %{fid}."  }
  end

  if length(revs) == 0 
    return { error: "Reverse primer stock(s) " + frag[0][:field4] + " missing for fragment %{fid}." }
  end

  return {
    fragment_id: fid,
    fragment_name: frag[0][:name],
    template_id:   temp[0][:id],
    template_name: temp[0][:sample][:name],
    forward_primer_id:   fwds[0][:id],
    forward_primer_name: fwds[0][:sample][:name],
    reverse_primer_id:   revs[0][:id],
    reverse_primer_name: revs[0][:sample][:name]
  }

end

function new_gel()

  # makes a new 12 lane gel

  produce silently
    gel = 1 "Gel"
    data
      matrix: [array_same(-1,12)]
    end  
  end

  return gel

end
