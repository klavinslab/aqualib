needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  def main

    fs = fragment_construction_status
    if fs[:fragments]
      waiting_ids = fs[:waiting_ids]
      users = waiting_ids.collect { |tid| find(:task, id: tid)[0].user.name }
      fragment_ids = waiting_ids.collect { |tid| find(:task, id: tid)[0].simple_spec[:fragments] }
      ready_to_build_fragment_ids = fs[:fragments][:ready_to_build].uniq
      not_ready_to_build_fragment_ids = fs[:fragments][:not_ready_to_build].uniq
      fs_tab = [[ "Not ready tasks", "Tasks owner", "Fragments", "Ready to build", "Not ready to build" ]]
      waiting_ids.each_with_index do |tid,idx|
        fs_tab.push [ tid, users[idx], fragment_ids[idx].to_s, (fragment_ids[idx]&ready_to_build_fragment_ids).to_s, (fragment_ids[idx]&not_ready_to_build_fragment_ids).to_s ]
      end
      show {
        title "Fragment Construction Status"
        note "Ready to build means recipes and ingredients for building this fragments are complete. Not ready to build means some information or stocks are missing."
        table fs_tab
      }
    end
    gs = gibson_assembly_status
    if gs[:fragments]
      waiting_ids = gs[:waiting_ids]
      users = waiting_ids.collect { |tid| find(:task, id: tid)[0].user.name }
      fragment_ids = waiting_ids.collect { |tid| find(:task, id: tid)[0].simple_spec[:fragments] }
      ready_to_use_fragment_ids = gs[:fragments][:ready_to_use].uniq
      not_ready_to_use_fragment_ids = gs[:fragments][:not_ready_to_use].uniq
      ready_to_build_fragment_ids = gs[:fragments][:ready_to_build].uniq
      not_ready_to_build_fragment_ids = gs[:fragments][:not_ready_to_build].uniq
      plasmid_ids = waiting_ids.collect { |tid| find(:task, id: tid)[0].simple_spec[:plasmid] }
      plasmids = plasmid_ids.collect { |pid| find(:sample, id: pid)[0]}
      # show {
      #   note "#{plasmids[0]}"
      # }
      # fragments = fragment_ids.collect { |fids| fids.collect { |fid| "#{find(:sample, id: fid)[0]}" }[0] }
      # show {
      #   note "#{fragment_ids}"
      # }
      gs_tab = [[ "Not ready tasks", "Tasks owner", "Plasmid", "Fragments", "Length info missing", "Ready to build", "Not ready to build" ]]
      waiting_ids.each_with_index do |tid,idx|
        gs_tab.push [ tid, users[idx], "#{plasmids[idx]}", fragment_ids[idx].to_s, (fragment_ids[idx]&not_ready_to_use_fragment_ids).to_s, (fragment_ids[idx]&ready_to_build_fragment_ids).to_s, (fragment_ids[idx]&not_ready_to_build_fragment_ids).to_s ]
      end
      show {
        title "Gibson Assemby Status"
        table gs_tab
      }
    end

  end # main

end # Protocol