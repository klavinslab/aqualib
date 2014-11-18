class PluginInterface < PluginInterfaceBase

  def data params
    view.logger.info "PARAMS = #{params}"
    return { login: view.current_user.login, name: view.current_user.name, params: params }
  end

end
