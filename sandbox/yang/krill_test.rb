needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning
 
  def arguments
    {x: 1379, y:"name", fid: 2574}
  end

  def main
    # def debug
    #   true
    # end
    x = input[:x]
    y = input[:y]
    plasmid_x1 = find(:item, id: 123)


    take plasmid_x1
    data = show {
    title "An input example"
    get "text", var: "y_data", label: "Enter a string", default: "Hello World"
    get "number", var: "z_data", label: "Enter a number", default: 555
    }
    y_data = data[:y_data]
    z_data = data[:z_data]
    show {
      title "Hello World!"
      note "y is #{y} and x is #{x}"
      note "y_data is #{y_data} and z_data is #{z_data}"
    }
    # fid = input[:fid]
    # fragment = find(:sample,{id: fid})[0]
    # stocks = fragment.items.select { |i| i.object_type.name == "Fragment Stock" && i.location != "deleted" }
    # stock_new = find(:sample, id: fid)[0].in("Fragment Stock")
    # show {
    #   note "#{stocks.collect {|s| s.id}}"
    #   note "#{stock_new.collect {|s| s.id}}"
    # } 
    # stocks = find(:sample, id:2382)[0].items.select { |i| i.object_type.name == "Yeast Glycerol Stock" }
    # stocks[1].location
    # stocks[1].location = "M80"
    # stocks[1].save
    # show {
    #   note "#{stocks[1].location}"
    # }

    

    phusion_stock_item = choose_sample "Phusion HF Master Mix"

    take [phusion_stock_item], interactive: true, method: "boxes" 

  end
  
end
