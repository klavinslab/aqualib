# class Protocol

# 	def debug
# 	  false
# 	end

# 	def main

# 		gels = take input[:gel_ids].collect { |i| collection_from i }

# 		show {
# 			title "Retrieve Gels"
# 			note "Get the gels with ids #{gels.collect { |g| g.id }}"
# 		}

# 		show {
# 			title "TODO"
# 			note "Describe how to slice the gels here"
# 		}

# 		slices = []

# 		gels.each do |gel|

# 			s = distribute( gel, "Gel Slice", except: [ [0,0], [1,0] ], interactive: true ) {
# 				title "Cut gel slices and place them in new 1.5 mL tubes"
# 				note "Label the tubes with the id shown"
# 			}

# 			produce s

# 			slices = slices.concat s

# 		end

# 		release slices, interactive: true, method: "boxes"

# 	end

# end

needs "aqualib/lib/standard"
class Protocol

  include Standard

  def debug
    false
  end

  def arguments
    {
      gel_ids: [12537],
      fragment_ids: [2568,2570,2571,2574,2576]
    }
  end

  def main
  	gels = input[:gel_ids].collect { |i| collection_from i }
  	take gels, interactive: true
  	# stripwells = input[:stripwell_ids].collect { |i| collection_from i }
  	# stripwells.each do |strip|
  	# 	strip.matrix.
  	fragment_lengths = input[:fragment_ids].collect {|f| find(:sample,{id: fid})[0].sample.properties["Length"]}
  	show {
  		title "Lengths of fragments"
  		note "#{fragment_lengths.collect {|f| f}}"
  	}

  	gels.each do |gel|
  		s = distribute( gel, "Gel Slice", except: [ [0,0], [1,0] ], interactive: true ) {
  			title "Cut gel slices and place them in new 1.5 mL tubes"
  			note "Label the tubes with the id shown above"
  		}
  		produce s
  		slices = slices.concat s
  	end

  	release slices, interactive: true, method: "boxes"

  end

end



