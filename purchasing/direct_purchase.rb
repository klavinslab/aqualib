# Title: Inventory Purchase Protocol
# Author: Eric Klavins
# Date: May 20, 2016 
 
class Protocol

  def main

    @object_types = ObjectType.all
    @job = Job.find(jid)
    @user = User.find(@job.user_id)
    user = @user # Can't put @user in show, becuase it would refer to the rwong object

    result = show do
      title "Choose a budget"
      note "User: #{user.name} (#{user.login})"
      select user.budget_info.collect { |bi| bi[:budget].name }, var: "choice", label: "Choose a budget", default: 1
    end
    
    @budget = Budget.find_by_name(result[:choice])
    @tasks = []
    
    i = 0
    again = true
    
    while again || i < 3
    
      result = show do
        title "Select Category"
        note "Basics: tubes, tip boxes, ..."
        note "Samples: media, ..."
        note "Batched: Gibson Aliquots, plates, ..."
        select [ "Basics", "Samples", "Batched" ], var: "choice", label: "Choose something", default: i
      end
      
      i += 1
    
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

    return {}

  end
  
  def choose_object_from objects
    result = show do
      title "Chose Object"
      select objects.collect { |ot| ot.name }, var: "choice", label: "Choose item", default: 0
    end
    objects.find { |b| b.name == result[:choice] }
  end
  
  ###############################################################################################################
  def basic_chooser 
      
    basics = @object_types.select { |ot| purchase_info(ot) == "basic" }      

    ot = choose_object_from basics
    m = ot.data_object[:materials]
    l = ot.data_object[:labor]
    message = "Purchase item #{ot.name}"

    if confirm message, currency(m+l) 
      task = make_purchase message, m, l
    end        
      
  end
  
  ###############################################################################################################
  def sample_chooser 
      
    samples = @object_types.select { |ot| purchase_info(ot) == "sample" }      
    ot = choose_object_from samples

    result = show do
      title "Chose Sample"
      select ot.data_object[:samples].collect { |s| s[:name] }, var: "choice", label: "Choose sample", default: 0
    end
    
    descriptor = ot.data_object[:samples].find { |d| d[:name] == result[:choice] }
    m = descriptor[:materials]
    l = descriptor[:labor]
    cost = currency(m+l)    
    del = descriptor[:delete]

    s = Sample.find_by_name(descriptor[:name])
    items = s.items.reject { |i| i.deleted? }
    
    if items.length > 0
      item = choose_item items, "Choose #{ot.name} of #{s.name} (#{cost} each)"
      message = "Purchase #{ot.name} of #{s.name}, item #{item.id}"
      if confirm message, cost
        take [item]
        task = make_purchase message, m, l
        release [item]
        if del
          item.mark_as_deleted
        end
      end
    else
      error "There are no items of #{ot.name}/#{s.name} in stock"
    end
              
  end
  
  ###############################################################################################################
  def batched_chooser 
 
    collections = @object_types.select { |ot| purchase_info(ot) == "collection" }      
    ot = choose_object_from collections
    
    result = show do
      title "Choose sample type" 
      select ot.data_object[:samples].collect { |s| s[:name] }, var: "choice", label: "Choose sample", default: 0
    end
    
    descriptor = ot.data_object[:samples].find { |d| d[:name] == result[:choice] }
    m = descriptor[:materials]
    l = descriptor[:labor]
    cost = currency(m+l)
    
    s = Sample.find_by_name(descriptor[:name])
    collections = ot.items.reject { |i| i.deleted? }.collect { |i| collection_from i }
    cids = collections.collect { |c| c.id }
    
    if cids.length > 0
    
      result = show do 
        title "Choose #{ot.name} and number of #{s.name.pluralize} (#{cost} each)"
        table [ [ "id", "Location", "Number of Samples" ] ] + (collections.collect { |i| [ i.id, i.location, i.num_samples ] } )
        select cids, var: "id", label: "Choose collection", default: 0
        get "number", var: "n", label: "How many #{s.name.pluralize}?", default: 2
      end
        
      collection = collections.find { |c| c.id == result[:id].to_i }
        
      n = [ collection.num_samples, [ 1, result[:n]].max ].min
      total_cost = currency(n*m+n*l)
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
    
    (0..m.length-1).each do |i|
      (0..m[i].length-1).each do |j|
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
      note "Please notify the lab manager of this problem"
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
            labor: lab
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
  
  def purchase_info ot
    if ot.data_object[:materials] && ot.data_object[:labor]
      "basic"
    elsif ot.handler == "sample_container" && ot.data_object[:samples]
      "sample"
    elsif ot.handler == "collection" && ot.data_object[:samples]
      "collection"
    else
      nil
    end
  end 

  def currency num
    ActionController::Base.helpers.number_to_currency num
  end  

end
