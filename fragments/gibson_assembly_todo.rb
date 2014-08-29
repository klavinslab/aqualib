module Cloning

  def fragment_info fid

    fragment = find(:sample,{id: fid})[0]# Sample.find(fid)
    props = fragment.properties

    fwd = props["Forward Primer"]
    rev = props["Reverse Primer"]
    template = props["Template"]

    if fwd == nil || rev == nil || template == nil

      return nil # Whoever entered this fragment didn't provide infor on how to make it

    else

      fwd_items = fwd.in "Primer Aliquot"
      rev_items = rev.in "Primer Aliquot"
      template_items = template.in "Plasmid Stock"

      if fwd_items.length == 0 || rev_items.length == 0 || template_items.length == 0

        return nil # There are missing items

      else

        t1 = fwd_items[0].sample.properties["Tm Anneal"] || 70.0
        t2 = rev_items[0].sample.properties["Tm Anneal"] || 70.0

        stocks = fragment.items.select { |i| i.object_type.name == "Fragment Stock" }

        return {
          fragment: fragment,
          stocks: stocks,
          fwd: fwd_items[0],
          rev: rev_items[0],
          template: template_items[0],
          tanneal: (t1+t2)/2.0
        }

      end

    end

  end # # # # # # # 

  def gibson_assembly_status

  	# find all un done gibson assembly tasks 
	tasks = find(:task,{task_prototype: { name: "Gibson Assembly" }})

	ready = tasks.select { |t| 
		t.status == "ready" 
	}

	running = tasks.select { |t| 
		t.status == "running"
	}

	out = tasks.select { |t| 
		t.status == "out for sequencing" 
	}

	# look up all fragments needed to 
	ready.each do |t|

		t[:fragments] = {
			ready_to_use: [],
			ready_to_build: [],
			not_ready_to_build: []
		}

		t.simple_spec[:fragments].each do |fid|

			info = fragment_info fid

			if !info
				t[:fragments][:not_ready_to_build].push fid
			elsif info[:stocks].length > 0
				t[:fragments][:ready_to_use].push fid
			else
				t[:fragments][:ready_to_build].push fid
			end

		end

	end

	return {

		fragments: ((tasks.select { |t| t.status == "ready" }).collect { |t| t[:fragments] })
			.inject { |all,part| all.each { |k,v| all[k].concat part[k] } },

		assemblies: {
			under_construction: running.collect { |t| t.id },
			waiting_for_ingredients: (ready.select { |t| t[:fragments][:ready_to_build] != [] || t[:fragments][:not_ready_to_build] != [] }).collect { |t| t.id },
			ready_to_build: (ready.select { |t| t[:fragments][:ready_to_build] == [] && t[:fragments][:not_ready_to_build] == [] }).collect { |t| t.id },
	    	out_for_sequencing: out.collect { |t| t.id }
	    }

	}

  end # # # # # # # 

end

class Protocol

	include Cloning

	def main

	  gas = gibson_assembly_status

	  show {
	  	title "Status"
	  	note gas
	  }

	  return gas

	end

end
