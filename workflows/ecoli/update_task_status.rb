needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol
	include Standard
	include Cloning

	def arguments
		{
			io_hash: {},
		}
	end

	def main
		tasks = find(:task,{task_prototype: { name: "Gibson Assembly" }})
		waiting = tasks.select { |t| t.status == "waiting for fragments" }
		ready = tasks.select { |t| t.status == "ready" }
		running = tasks.select { |t| t.status == "running" }
		out = tasks.select { |t| t.status == "out for sequencing" }


		# look up all fragments needed to assemble, and sort them by whether they are ready to build, etc.
		(waiting + ready).each do |t|

		  t[:fragments] = { ready_to_use: [], ready_to_build: [], not_ready_to_build: [] }

		  t.simple_spec[:fragments].each do |fid|

		    info = fragment_info fid

		    # First check if there already exists fragment stock, if so, it's ready to build.
		    if find(:sample, id: fid)[0].in("Fragment Stock").length > 0
		      t[:fragments][:ready_to_use].push fid
		    elsif !info
		      t[:fragments][:not_ready_to_build].push fid
		    # elsif info[:stocks].length > 0
		    #   t[:fragments][:ready_to_use].push fid
		    else
		      t[:fragments][:ready_to_build].push fid
		    end

		  end

		# change tasks status based on whether the fragments are ready.
		  if t[:fragments][:ready_to_use].length == t.simple_spec[:fragments].length
		    t.status = "ready"
		    t.save
		    show {
		      note "status changed to ready"
		      note "#{t.id}"
		    }
		  elsif t[:fragments][:ready_to_use].length < t.simple_spec[:fragments].length
		    t.status = "waiting for fragments"
		    t.save
		    show {
		      note "status changed to waiting"
		      note "#{t.id}"
		    }
		  end

		  show {
		    note "After processing"
		    note "#{t[:fragments]}"
		  }
		end
	end
end
