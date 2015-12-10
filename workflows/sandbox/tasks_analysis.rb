needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  def arguments
    {

    }
  end

  def main
    seq_veri_tasks = find(:task, { task_prototype: { name: "Sequencing Verification" } })
    done_seq_veri_tasks = seq_veri_tasks.select { |t| t.status == "done" && t.id > 10000 }
    redundant_tasks = done_seq_veri_tasks.select { |t| t.notifications.collect { |notif| notif.content }.join.include? "sequence correct but redundant" }
    correct_tasks, wrong_tasks, redundant_tasks = [], [], []
    done_seq_veri_tasks.each do |t|
      history = t.notifications.collect { |notif| notif.content }.join
      if history.include? "'results back' to 'sequence correct but redundant'"
        redundant_tasks.push t
      elsif history.include? "'results back' to 'sequence correct'"
        correct_tasks.push t
      elsif history.include? "sequence wrong"
        wrong_tasks.push t
      end
    end

    show {
      note seq_veri_tasks.length
      note done_seq_veri_tasks.length
      note "correct tasks #{correct_tasks.length}, #{correct_tasks.length.to_f/done_seq_veri_tasks.length}"
      note "redundant tasks #{redundant_tasks.length}, #{redundant_tasks.length.to_f/done_seq_veri_tasks.length}"
      note "wrong tasks #{wrong_tasks.length}, #{wrong_tasks.length.to_f/done_seq_veri_tasks.length}"
    }

  end
end
