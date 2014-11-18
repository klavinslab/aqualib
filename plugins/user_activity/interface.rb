class PluginInterface < PluginInterfaceBase

  def data params

    num = params[:num] ? params[:num] : 7

    latest_jobs = Job.includes(:user).where("created_at > ? AND user_id >= 0", Time.now-num.days)

    users = (latest_jobs.collect { |j| { login: j.user.login, id: j.user.id } }).uniq

    data = users.collect { |user|
      jobs = (latest_jobs.select { |j| j.user.id == user[:id] })
      user.merge({
        count: jobs.length,
        latest: view.time_ago_in_words((jobs.sort { |j| j.created_at.to_i }).first.created_at) + " ago"
      })
    }

    return {
      data: data.sort { |x,y| y[:count] <=> x[:count] },
      days: num
    }

  end

end 
