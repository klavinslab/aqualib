class Protocol

  def arguments
      {
        io_hash: {},
        plate_batch_id: 70708
      }
  end

  def main
  io_hash = input[:io_hash]
  io_hash = input if input[:io_hash].empty?
  plate_batch = find(:item, id: io_hash[:plate_batch_id])[0]
  take [plate_batch], interactive: true
    show {
      title "Move Plates To Storage Containers"
      note "Find an empty storage container on top of the media fridge."
      note "Remove any labeling tape that might be on the container."
      note "Move one of the labels on the plate stack to the front of the storage container."
      note "Move plates #{plate_batch} to the storage container."
    }

    plate_batch.location = "Media Fridge"

    release [plate_batch], interactive: true
    return {io_hash: io_hash}

    end

end
