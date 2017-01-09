# Title: Inventory Purchase Protocol
# Author: Eric Klavins
# Date: May 31, 2016 

class Protocol
  
  def main

    @object_types = ObjectType.all
    @job = Job.find(jid)
    @user = User.find(@job.user_id)
    user = @user # Can't put @user in show, becuase it would refer to the wrong object

    result = show do
      title "Choose a budget"
      note "User: #{user.name} (#{user.login})"
      select user.budget_info.collect { |bi| bi[:budget].name }, var: "choice", label: "Choose a budget", default: 1
    end
    
    @budget = Budget.find_by_name(result[:choice])
    @overhead = Parameter.get_float("markup rate")
    @tasks = []
    
    again = true
    
    while again 
    
      result = show do
        title "Select Category"
        note "Basics: tubes, tip boxes, ..."
        note "Samples: media, ..."
        note "Batched: Gibson Aliquots, plates, ..."
        select [ "Basics", "Samples", "Batched" ], var: "choice", label: "Choose something", default: 1
      end
      
      case result[:choice]
        when "Basics"then basic_chooser
        when "Samples" then sample_chooser 
        when "Batched" then batched_chooser
      end
      
      transactions = @tasks.collect { |t| t.accounts }.flatten
      tab = [ [ "Description", "Amount" ] ] + transactions.collect { |t|
        [ 
         t.description.split(":")[0].split(" - ")[1], 
          currency((1+t.markup_rate)*t.amount) 
        ] 
      }
    
      result = show do
        title  "Summary"
        table tab if tab.length > 1 
        note "No purchases made" unless tab.length > 1
        select [ "No", "Yes" ], var: "again", label: "Would you like to make another purchase?", default: 0
      end
    
      again = ( result[:again] == "Yes" )
      
    end
     return { }
   end

  def choose_object_from objects, number=false
    result = show do
      title "Chose Object"
      select objects.collect { |ot| ot.name }, var: "choice", label: "Choose item", default: 0
      get "number", var: "n", label: "How many?", default: 5 if number
    end
    return objects.find { |b| b.name == result[:choice] } unless number
    return [ objects.find { |b| b.name == result[:choice] }, result[:n] ] if number
  end
  
  ###############################################################################################################
  def basic_chooser 
    
    basics = @object_types.select { |ot| basic? ot }      
    ot, n = choose_object_from basics, true
  
    m = ot.data_object[:materials]
    l = ot.data_object[:labor]
    u = ot.data_object[:unit] 
    vol[:n] = 1

    if u 
      vol = show do
        title "Choose Volume"
        get "number", var: "n", label: "How many #{u}'s of #{ot.name}?", default: 5
        select ["Yes", "No"], var: "delete", label: "Are you purchasing the whole container or is the container now empty?", default: "No"
      end
    end

    message = "Purchase #{n} #{ot.name.pluralize}"
    if confirm message, currency((1+@overhead) * n * (m+l) * vol[:n]) 
      task = make_purchase message, n*m*vol[:n], n*l*vol[:n]
    end        
    
  end

  ###############################################################################################################
  def sample_chooser 
   
    samples = @object_types.select { |ot| sample? ot }      
    ot = choose_object_from samples
    result = show do
      title "Choose Sample"
      select ot.data_object[:samples].collect { |s| s[:name] }, var: "choice", label: "Choose sample", default: 2
    end
    
    descriptor = ot.data_object[:samples].find { |d| d[:name] == result[:choice] }
    m = descriptor[:materials]
    l = descriptor[:labor]
    u = descriptor[:unit]
    s = descriptor[:name] 
    vol = {}

    items = Sample.find_by_name(s).items.reject { |i| i.deleted? }
    
    if items.length > 0
      item = choose_item items, "Choose #{ot.name} of #{s}"

      vol = show do
        title "Choose Volume"
        get "number", var: "n", label: "How many #{u}'s of #{s}?", default: 5
        select ["Yes", "No"], var: "delete", label: "Are you purchasing the whole container or is the container now empty?", default: "No"
      end


      cost = currency((1+@overhead)*(m+l) * vol[:n]) 
      message = "Purchase #{ot.name} of #{s}, item #{item.id}"
      if confirm message, cost
        take [item]
        task = make_purchase message, m*vol[:n], l*vol[:n]
        release [item]
        if (descriptor[:delete] || vol[:delete] == "Yes")
          item.mark_as_deleted
        end
      end
    else
      error "There are no items of #{ot.name}/#{s.name} in stock"
    end 
  end    
  ###############################################################################################################
  def batched_chooser 

    collections = @object_types.select { |ot| batched? ot }
    ot = choose_object_from collections
  
    result = show do
      title "Choose sample type" 
      select ot.data_object[:samples].collect { |s| s[:name] }, var: "choice", label: "Choose sample", default: 0
    end
  
    descriptor = ot.data_object[:samples].find { |d| d[:name] == result[:choice] }
    m = descriptor[:materials]
    l = descriptor[:labor]
    cost = currency((1+@overhead)*(m+l))
  
    s = Sample.find_by_name(descriptor[:name])
    collections = ot.items.reject { |i| i.deleted? }.collect { |i| collection_from i }
    # filter out collections based on user's sample input
    collections.reject! { |c| c.matrix[0][0] != s.id }
    cids = collections.collect { |c| c.id }
  
    if cids.length > 0
  
      result = show do 
        title "Choose #{ot.name} and number of #{s.name.pluralize} (#{cost} each)"
        table [ [ "id", "Location", "Number of Samples" ] ] + (collections.collect { |i| [ "#{i}", i.location, i.num_samples ] } )
        select cids, var: "id", label: "Choose collection", default: 0
        get "number", var: "n", label: "How many #{s.name.pluralize}?", default: 2
      end
      
      collection = collections.find { |c| c.id == result[:id].to_i }
      
      n = [ collection.num_samples, [ 1, result[:n]].max ].min
      total_cost = currency((1+@overhead)*(n*m+n*l))
      message = "Purchase #{n} #{s.name.pluralize} from #{ot.name} #{collection.id}"
      
      if confirm message, total_cost 
        take_samples collection, n
        task = make_purchase message, n*m, n*l
        release [collection]
        if collection.num_samples == 0
          collection.mark_as_deleted
        end
      end    
    else
      error "There are no #{ot.name} in stock"
    end
  end

  def take_samples collection, n
   
    m = collection.matrix
    x = 0
  
    (0..m.length-1).reverse_each do |i|
      (0..m[i].length-1).reverse_each do |j|
        if m[i][j] != -1 && x < n
          m[i][j] = -1
          x += 1
        end
      end
    end
  
    collection.matrix = m
    collection.save
    take [collection]
    
  end

  def error msg, details=nil
    show do 
      title msg
      note details if details
      note "Please report this problem to a BIOFAB lab manager."
    end      
  end

  def confirm message, cost
    result = show do 
      title message
      note "Cost: #{cost}"
      select [ "Ok", "Cancel" ], var: "choice", label: "Ok to purchase?", default: 0
    end
    return (result[:choice] == "Ok")
  end

  def choose_item items, message
    result = show do 
      title message
      items.each do |i|
        item i
      end
      select items.collect { |i| i.id }, var: "choice", label: "Choose item", default: 0
    end
    Item.find(result[:choice])          
  end


  def make_purchase description, mat, lab
    tp = TaskPrototype.find_by_name("Direct Purchase")
    if tp
      task = tp.tasks.create({
        user_id: @user.id, 
        name: "#{DateTime.now.to_i} - #{description}",
        status: "purchased",
        budget_id: @budget.id,
        specification: {
            description: description,
            materials: mat,
            labor: lab,
         }.to_json
      })
      task.save
      if task.errors.empty?
        set_task_status(task,"purchased")          
      else
        error "Errors", task.errors.full_messages.join(', ')
      end
      @tasks << task
      task
    end
  end

  def valid_sample_descriptor s
    val = s[:name]      && s[:name].class == String &&
          s[:materials] && ( s[:materials].class == Float || s[:materials].class == Fixnum ) &&
          s[:labor]     && ( s[:labor].class == Float     || s[:labor].class == Fixnum )    
    error("Bad descriptor", s.to_s) unless val
    val
  end

  def basic? ot
    ot.handler != "sample_container" && ot.handler != "collection"  &&
    ot.data_object[:materials] && ot.data_object[:labor]      
  end

  def sample? ot
    ot.handler == "sample_container" && ot.data_object[:samples] && 
    ot.data_object[:samples].each { |s| return nil unless valid_sample_descriptor s }
  end

  def batched? ot
    ot.handler == "collection" && ot.data_object[:samples] && 
    ot.data_object[:samples].each { |s| return nil unless valid_sample_descriptor s }
  end

  def currency num
    ActionController::Base.helpers.number_to_currency num
  end  

end
