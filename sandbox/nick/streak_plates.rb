needs "aqualib/lib/standard"

class Protocol
  def arguments
    {plate_ids: [4977] # Replace with e.g. "plate_ids Plasmid => [0]"
    }
  end

  def main
    plate_ids = input[:plate_ids]

    # Figure out the types / number of media needed for each plate (media = array)
    plate_ids.each do |pid|
      plate_sample = find(:item, id: pid)[0].sample
      show {
        note plate_sample.properties.keys
      }
    end
    # Take out the right number of each plate type (array -> counter hash)
    # Streak out strain i onto plate of type media[i]
    # Produce each plate after streaking, consuming the taken plate
    # Put away the produced plates
    # Put away the plates that were taken out
  end
end
