needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  def arguments
    {
      io_hash: {},
      "ids Yeast Plate"=> [15056],
      debug_mode: "Yes"
    }
  end

  def main
    io_hash = input[:io_hash]
    io_hash = input if !input[:io_hash] || input[:io_hash].empty?
    io_hash[:debug_mode] = input[:debug_mode] || "No"
    if io_hash[:debug_mode].downcase == "yes"
      def debug
        true
      end
    end

    tp = TaskPrototype.where("name = 'Gibson Assembly'")[0]
    yeast_strains = SampleType.where("name = 'Yeast Strain'")[0].samples
    frags = SampleType.where("name = 'Fragment'")[0].samples
    primers = SampleType.where("name = 'Primer'")[0].samples
    users = User.all

    (1..5).each do |i|

      t = Sample.new
      t.name = "Gibson#{i+15}"
      t.sample_type_id = tp.id
      t.user_id = users.sample.id
      t.description = "Gibson#{i+10}"
      t.project = "Bandpass Filter"
      t.field6 = "diploid"

      t.save

      show {
        note t.id
      } 

    end

  end # main
end # Protocol
