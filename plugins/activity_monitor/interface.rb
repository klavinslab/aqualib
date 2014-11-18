class PluginInterface < PluginInterfaceBase

  def data params

    now = Time.now
    since = Time.at(params[:since])

    s = Sample.where("created_at >= ? AND created_at < ?", since, now)
        .collect { |s| { updated_at: s.created_at, id: s.id } }

    result = { 
      start: since,
      timestamp: now,
      jobs: Job.where("updated_at >= ? AND updated_at < ? AND pc = -2", since, now)
        .collect { |j| { updated_at: j.updated_at, id: j.id } },
      samples: s
    }

    return result

  end

end
