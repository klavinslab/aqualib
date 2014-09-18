needs "aqualib/lib/standard"

class Protocol
  def arguments
    { plate_ids: Sample.where("sample_type='E coli Plate'")[0]
    }
  end

  def main
    bacterial_plates = input["bacterial_plates"]
    show {
      note bacterial_plates
    }
  end
end
