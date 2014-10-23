needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning
 

    def choose_sample sample_name, p={}

        # Directs the user to take an item or items associated with the sample defined by sample_name.
        # Options:
        #   multiple : false          --> take one or take multiple items. if multiple, then a list of items is returned
    #   quantity : n              --> the number of items to take. sets multiple to true if greater than 1
    #   take : false              --> does an interactive take if true


    if block_given?
      user_shows = ShowBlock.new.run(&Proc.new) 
    else
      user_shows = []
    end

        params = ({ multiple: false, quantity: 1, take: false }).merge p
        params[:multiple] = true if params[:quantity] > 1

        options = find(:item, sample: {name: sample_name}).reject { |i| /eleted/ =~ i.location }
        raise "No choices found for #{sample_name}" if options.length == 0

        choices = options.collect { |ps| "#{ps.id}: #{ps.location}" }

        quantity = -1

        user_input = {}

        while quantity != params[:quantity] || !user_input[:x]

            user_input = show {
                if params[:quantity] == 1
                  title "Choose a #{sample_name}"
                else
                  title "Choose #{params[:quantity]} #{sample_name.pluralize}"
                end
              if quantity >= 0 
                note "Try again. You chose the wrong number of items"
              end
              raw user_shows
              select choices, var: "x", label: "Choose #{params[:quantity]} #{sample_name}", multiple: params[:multiple]
            }

            if params[:quantity] != 1 && user_input[:x]
                quantity = user_input[:x].length
            else
                quantity = 1
            end

        end

        # show {
        #   note "#{user_input[:x]}" + "and" + " #{quantity}"
        # }

        # if params[:quantity] == 1 && !params[:multiple]
        #     user_input[:x] = [ user_input[:x] ]
        # end

        user_input[:x] = [ user_input[:x] ] unless user_input[:x].kind_of?(Array)

        # show {
        #   note "#{user_input[:x]}" + "and" + " #{quantity}"
        # }

        items = user_input[:x].collect { |y| options[choices.index(y)] }

        if params[:take]
            take items, interactive: true, method: "boxes"
        end

        if params[:multiple]
            return items
        else
            return items[0]
        end

        # proposed change
        # return items  

    end

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



    phusion_stock_item = choose_sample "Phusion HF Master Mix", take: true, multiple: true 

#    take [phusion_stock_item], interactive: true, method: "boxes" 

  end
  
end
