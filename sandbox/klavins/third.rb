class Protocol

  def main

    items = find(:item, { sample: { name: "pLAB1" }, object_type: { name: "Plasmid Stock" } } )[0,6]

    take(items, interactive: true) { 
		  warning "Do not leave the freezer open too long!"
    }

    show { title "Thanks for taking the items" }

    release(items, interactive: true) {
	   	warning "Do not leave the freezer open too long!"
    }

    show { title "Thanks for releasing the items" }

  end

end
