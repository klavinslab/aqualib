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

    object_types = ObjectType.all
    basics = object_types.select { |ot| purchase_info(ot) == "basic" }
    samples = object_types.select { |ot| purchase_info(ot) == "sample" }
    collections = object_types.select { |ot| purchase_info(ot) == "collection" }

    result = show do
      title "Select Category"
      note "Basics: tubes, tip boxes, ..."
      note "Samples: media, ..."
      note "Batched: Gibson Aliquots, plates, ..."
      select [ "Basics", "Samples", "Batched" ], var: "choice", label: "Choose something", default: 1
    end

    case result[:choice]

      when "Basics"

        result = show do
          title "Chose Object"
          select basics.collect { |ot| ot.name }, var: "choice", label: "Choose item", default: 0
        end

        ot = basics.find { |b| b.name == result[:choice] }
        m = currency(ot.data_object[:materials])
        l = currency(ot.data_object[:labor])
        
        result = show do
          title "#{result[:choice]} Costs"
          note "Material: #{m}"
          note "Labor: #{l}"
          select [ "Ok", "Cancel" ], var: "choice", label: "Choose item", default: 0
        end
            
        task = make_purchase ot.name, ot.data_object[:materials], ot.data_object[:labor]
        
        show do
          title "Created task number #{task.id}"
        end
        
      when "Samples"

        result = show do
          title "Chose Object"
          select samples.collect { |ot| ot.name }, var: "choice", label: "Choose sample", default: 0
        end
        
        ot = samples.find { |b| b.name == result[:choice] }
        
        result = show do
          title "Chose Sample"
          select ot.data_object[:samples].collect { |s| s[:name] }, var: "choice", label: "Choose sample", default: 0
        end
        
        s = Sample.find_by_name(result[:choice])
        items = s.items.reject { |i| i.deleted? }
        
        result = show do 
          title "Choose item"
          items.each do |i|
            item i
          end
          select items.collect { |i| i.id }, var: "choice", label: "Choose item", default: 0
        end
        
      when "Batched

        show do
          title "Chose Batch Item"
          select collections.collect { |ot| ot.name }, var: "choice", label: "Choose batch item", default: 0
        end

    end

    return {

      user: @user.login,
      job: @job.id

    }

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
