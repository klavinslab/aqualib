class PluginInterface < PluginInterfaceBase

  def data params

    now = Time.now

    jobs = Job.where("pc >= -1")

    jobs.each { |j| 
      g = Group.find(j.group_id)
      j[:submitted_login] = User.find(j.submitted_by).login
      j[:group_name] = g.name
      if !(j.pc == -1 && now <= j.desired_start_time) && g.member?(@view.current_user.id)
        j[:start] =  j.start_link("<i class='icon-play'></i>",confirm:true)
      else
        j[:start] = ""
      end
      j[:metacol_id] = j.metacol ? j.metacol.id : -1
      j[:last_update] = (view.time_ago_in_words j.updated_at) + " ago"
    }

    return {
      active:  jobs.select { |j| j.pc >= 0 },
      urgent:  jobs.select { |j| j.pc == -1 && j.latest_start_time < now },
      pending: jobs.select { |j| j.pc == -1 && j.desired_start_time < now && now <= j.latest_start_time },
      future:  jobs.select { |j| j.pc == -1 && now <= j.desired_start_time },
      current_user: @view.current_user
    }
    
  end

end
