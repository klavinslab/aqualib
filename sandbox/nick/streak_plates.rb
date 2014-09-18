needs "aqualib/lib/standard"

class Protocol
  def arguments
    {plate_ids: find(:item, sample: {object_type: {name: "E coli Plate"}})[0]
    #Item.where("object_type='E coli Plate'")[0]
    }
  end

  def main
    bacterial_plates = input["bacterial_plates"]
    show {
      note bacterial_plates
    }
  end
end
