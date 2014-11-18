needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  def main

    gs = gibson_assembly_status
    waiting_ids = gs[:waiting_ids]
    users = waiting_ids.collect { |tid| find(:task, id: tid)[0].user.name }
    fragment_ids = waiting_ids.collect { |tid| find(:task, id: tid)[0].simple_spec[:fragments] }
    plasmid_ids = waiting_ids.collect { |tid| find(:task, id: tid)[0].simple_spec[:plasmid] }
    plasmids = plasmid_ids.collect { |pid| find(:sample, id: pid)[0]}
    # fragments = fragment_ids.collect { |fids| fids.collect { |fid| "#{find(:sample, id: fid)[0]}" }[0] }
    # show {
    #   note "#{fragment_ids}"
    # }
    gs_tab = [[ "List of not ready tasks", "Tasks owner", "Fragments", "Plasmid" ]]
    waiting_ids.each_with_index do |tid,idx|
      gs_tab.push [ tid, users[idx], fragment_ids[idx].to_s, "#{plasmids[idx]}"]
    end
    show {
      title "Gibson Assemby Status"
      table gs_tab
      if gs[:fragments]
        note "Ready to use fragment ids: #{gs[:fragments][:ready_to_use].uniq}"
        note "Not ready to use fragment ids, probably missing length info: #{gs[:fragments][:not_ready_to_use].uniq}"
        note "Ready to build fragment ids: #{gs[:fragments][:ready_to_build].uniq}" 
        note "Not ready to build fragment ids: #{gs[:fragments][:not_ready_to_build].uniq}"
      end
    }

  end # main

end # Protocol