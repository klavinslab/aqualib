class PluginInterface < PluginInterfaceBase

  def data params

    metacols = Metacol.includes(:user).where(status: "RUNNING")

    metacols.each do |m|
      m[:login] = m.user.login
      m[:date] = (view.time_ago_in_words m.updated_at) + " ago"
    end
    return { metacols: metacols, current_user: @view.current_user }
  end

end
