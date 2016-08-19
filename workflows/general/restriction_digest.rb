needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  def arguments
    {
      io_hash: {},
      template_ids: [],
      enzymes: [],
      band_lengths: []
    }
  end #arguments

  def main
    io_hash = input[:io_hash]
    io_hash = input if input[:io_hash].empty?
    io_hash = { debug_mode: "Yes", gibson_result_ids: [], plasmid_item_ids: [], task_ids: [], group: "technicians"}.merge io_hash
    if io_hash[:debug_mode].downcase == "yes"
      def debug
        true
      end
    end
  end
end