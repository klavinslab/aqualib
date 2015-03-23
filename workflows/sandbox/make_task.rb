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
    plasmids = SampleType.where("name = 'Plasmid'")[0].samples
    frags = SampleType.where("name = 'Fragment'")[0].samples
    primers = SampleType.where("name = 'Primer'")[0].samples
    users = User.all

    (1..25).each do |i|

      t = Task.new
      t.name = "Gibson#{i+10}"
      t.specification = ({
        "plasmid Plasmid" => plasmids.sample.id,
        "fragments Fragment" => frags.sample(3).collect { |f| f.id },
      }).to_json
      t.task_prototype_id = tp.id
      t.status = "waiting"
      t.user_id = users.sample.id

      show {
        note "#{t.attributes.to_s}"
      }

      t.save

      show {
        note t.id
      } 

    end

  end # main
end # Protocol
