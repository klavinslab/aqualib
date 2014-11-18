class PluginInterface < PluginInterfaceBase

  def data params

    begin
      krill_response = Krill::Client.new.jobs
    rescue Exception => e
      krill_response = { error: e.to_s }
    end

    active_krill_jobs = (Job.where("pc >= 0").select { |j| /\.rb/ =~ j.path }).collect { |j| j.id }

    ps = `ps waux | grep runner`

    return { 
      krill_response: krill_response, 
      active_krill_jobs: active_krill_jobs, 
      timestamp: Time.now, 
      ps: ps.split("\n")
    }

  end

end
