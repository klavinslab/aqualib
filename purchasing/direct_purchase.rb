# Title: Inventory Purchase Protocol
# Author: Eric Klavins
# Date: May 20, 2016 
 
class Protocol

  def main

    @job = Job.find(jid)
    @user = User.find(@job.user_id)
    user = @user # Can't put @user in show, becuase it would refer to the rwong object

    result = show do
      title "Choose a budget"
      note "User: #{user.name} (#{user.login})"
      select user.budget_info.collect { |bi| bi[:budget].name }, var: "choice", label: "Choose a budget", default: 1
    end
    
    @budget = Budget.find_by_name(result[:choice])
    @object_types = ObjectType.all
    
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
    m = currency(ot.data_object[:materials])
    l = currency(ot.data_object[:labor])
    
    result = show do
      title "#{result[:choice]} Costs"
      note "Material: #{m}"
      note "Labor: #{l}"
      select [ "Ok", "Cancel" ], var: "choice", label: "Choose item", default: 0
    end
    
    if result[:choice] == "Ok"    
      task = make_purchase ot.name, ot.data_object[:materials], ot.data_object[:labor]
      show do
        title "Created task number #{task.id}"
      end
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
    del = descriptor[:delete]
    mc = currency(m)
    lc = currency(l)
    cost = currency(m+l)
    
    s = Sample.find_by_name(descriptor[:name])
    items = s.items.reject { |i| i.deleted? }
    
    result = show do 
      title "Choose item"
      note "#{cost} each"
      items.each do |i|
        item i
      end
      select items.collect { |i| i.id }, var: "choice", label: "Choose item", default: 0
    end
    
    item = Item.find(result[:choice])

    
    result = show do
      title "#{ot.name} / #{s.name} Costs"
      note "Item: #{item.id}"
      note "Material: #{mc}"
      note "Labor: #{lc}"
      select [ "Ok", "Cancel" ], var: "choice", label: "Choose item", default: 0
    end        
    
    if result[:choice] == "Ok"    
      task = make_purchase "#{ot.name}/#{s.name}/#{item.id}", m, l
      show do
        title "Created task number #{task.id}"
      end
      if del
        item.mark_as_deleted
        show do
          title "Deleted item #{item.id}"
        end            
      end
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

    result = show do 
      title "Choose collection"
      table [ [ "id", "Location", "Number of Samples" ] ] + (collections.collect { |i| [ i.id, i.location, i.num_samples ] } )
      select collections.collect { |c| c.id }, var: "id", label: "Choose collection", default: 0
      get "number", var: "n", label: "How many samples (#{cost} each)?", default: 14
    end
    
    collection = collections.find { |c| c.id == result[:id].to_i }
    
    n = [ collection.num_samples, [ 1, result[:n]].max ].min

    mc = currency(n*m)
    lc = currency(n*l)
    
    show do 
      title "Purchase #{n} samples from collection #{collection.id}" 
      note "Material: #{mc}"
      note "Labor: #{lc}"
      select [ "Ok", "Cancel" ], var: "choice", label: "Choose item", default: 0
    end

  end
  
  def make_purchase description, mat, lab
    tp = TaskPrototype.find_by_name("Direct Purchase")
    if tp
      task = tp.tasks.create({
        user_id: @user.id, 
        name: "#{DateTime.now.to_i}: #{description}",
        status: "purchased",
        budget_id: @budget.id,
        specification: {
            description: description,
            materials: mat,
            labor: lab
         }.to_json
      })
      task.save
      unless task.errors.empty?
        show do
          title "Errors"
          note task.errors.full_messages.join(', ')
        end
      end
      set_task_status(task,"purchased")
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
