class PluginInterface < PluginInterfaceBase

  def data params

    @view.logger.info "AAAAAA"
    now = Time.now
    since = Time.at(params[:since])

    result = { 
      start: since,
      timestamp: now,
      jobs: Job.where("updated_at >= ? AND updated_at < ? AND pc = -2", since, now)
        .collect { |j| { updated_at: j.updated_at, id: j.id } },
      samples: Sample.where("created_at >= ? AND created_at < ?", since, now)
        .collect { |s| { updated_at: s.updated_at, id: s.id } },
    }

    @view.logger.info "BBBBBBB"

    return result

  end

end
