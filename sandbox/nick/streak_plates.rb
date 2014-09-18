needs "aqualib/lib/standard"

class Protocol
  def arguments
    {plate_item_ids: [4977] # Replace with e.g. "plate_item_ids Plasmid => [0]"
    }
  end

  def main
    plate_ids = input[:plate_item_ids]

    # Figure out the types / number of media needed for each plate (media = array)
    plate_ids.each do |pid|
      plate_sample = find(:item, id: pid)[0].sample
      resistance_raw = plate_sample.properties["Bacterial Marker"]
      if resistance_raw.downcase.include? "amp"
        resistance = "amp"
      elsif resistance_raw.downcase.include? "kan"
        resistance = "kan"
      elsif resistance_raw.downcase.include? "chlor"
        resistance = "chlor"
      else
        # For now, catching a wrong/empty value does the same thing
        if y.length = 0
          show {
            title "Bacterial marker undefined"
            note "Aquarium couldn't figure out the bacterial resistance associated with one of the input plates. This sample will not be plated."
          }
        else
          show {
            title "Unrecognized bacterial marker"
            note "Aquarium couldn't figure out the bacterial resistance associated with one of the input plates. This sample will not be plated."
            # Figure out a way to prompt for the right value / notify the scheduler. This affects the length of the output
          }
        end
      end

      show {
        note plate_sample.properties["Bacterial Marker"]
      }
    end

    # DEBUG: find all E coli Plates
    ecoli_plates = find(:item, sample: {:object_type: {name: "E coli Plate"}})
    show {
      note ecoli_plates
    }

    # Take out the right number of each plate type (array -> counter hash)
    # Streak out strain i onto plate of type media[i]
    # Produce each plate after streaking, consuming the taken plate
    # Put away the produced plates
    # Put away the plates that were taken out
  end
end
