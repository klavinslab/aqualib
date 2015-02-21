class PluginInterface < PluginInterfaceBase

  def data params

    now = Time.now

    jobs = Job.includes(:metacol,:group => :memberships).where("pc >= -1")

    jobs.each { |j| 
      g = j.group
      j[:submitted_login] = User.find(j.submitted_by).login
      if j.user
        j[:user_login] = User.find(j.user).login      
      end
      j[:group_name] = g ? g.name : 'no group'
      if !(j.pc == -1 && now <= j.desired_start_time) && (!g || g.member?(@view.current_user.id) )
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
