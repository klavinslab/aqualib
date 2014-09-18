needs "aqualib/lib/standard"

class Protocol
  def arguments
    {plate_ids: [4977]}
  end

  def main
    input_plates = input["bacterial_plates"]
    show {
      note input_plates.to_s
    }
  end
end
