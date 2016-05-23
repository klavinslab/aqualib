# Title: Inventory Purchase Protocol
# Author: Eric Klavins
# Date: May 20, 2016

class Protocol

  def main

    job = Job.find(jid)
    user = User.find(job.user_id)

    show do
      note "Current User: #{user.name} (#{user.login})"
      select user.budget_info.collect { |bi| bi[:budget].name }, var: "budget", label: "Choose a budget", default: 0
    end

    object_types = ObjectType.all

    basics = object_types.select { |ot|
      purchase_info(ot) == "basic"
    }

    samples = object_types.select { |ot|
      purchase_info(ot) == "sample"
    }

    collections = object_types.select { |ot|
      purchase_info(ot) == "collection"
    }

    result = show do
      title "Select Category"
      note "Basics: e.g. tubes and tip boxes"
      note "Samples: e.g. media"
      note "Batched: e.g. Gibson Aliquots and plates"
      select [ "Basics", "Samples", "Batched" ], var: "choice", label: "Choose something", default: 0
    end

    case result[:choice]

      when "Basics"

        result = show do
          title "Chose Item"
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
        
      when "Samples"

        show do
          title "Chose Item"
          select samples.collect { |ot| ot.name }, var: "choice", label: "Choose sample", default: 0
        end

      when "Batched"

        show do
          title "Chose Batch Item"
          select collections.collect { |ot| ot.name }, var: "choice", label: "Choose batch item", default: 0
        end

    end

    return {
      user: user.login,
      job: job.id
    }

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
