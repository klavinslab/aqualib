class Protocol

  def main

    more = true

    while more

      data = show {
        title "Upload a file"
        upload var: "u"
      }

      uploads = data[:u].collect { |u| find(:upload,{id: u[:id]})[0] }

      data = show {
        title "Result"
        table uploads.collect { |u| [ u.id, u.name ] }
        select ["Yes","No"], var: "more", label: "Another Upload?"
      }

      more = (data[:more]=="Yes")

    end

  end

end