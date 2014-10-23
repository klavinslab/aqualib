needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  def arguments
    {
      io_hash: {},
      "overnight_ids Yeast Overnight Suspension" => [],
      debug_mode: "Yes"
    }
  end

  def main
  	overnights = input[:overnight_ids].collect { |oid| find(:item, id: oid) }
  	take overnights, interactive: true
  	show {
  		title "Put them in the dish washing station"
  		check "Take all the overnight tubes to the washing station"
  	}
  	overnights.each do |x|
  		x.mark_as_deleted
  		x.save
  	end

  	release overnights
  end
end
