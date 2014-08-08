class Protocol

  def main

    i = produce new_object "1 L Bottle"
    j = produce new_sample "pLAB1", of: "Plasmid", as: "Plasmid Stock"
    j.set_data [ 0, { x: 'some data here' } ]

    show {
      note "#{i.id}: #{i.location}"
      note "#{j.id}: #{j.location}"
      note "data associated with j = #{j.get_data}"
    }

    release([i,j], interactive: true)

  end

end
