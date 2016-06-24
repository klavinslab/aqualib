class Protocol
	
	def arguments
    		{
    		}
	 end
	
	def main
		tp = TaskPrototype.where("name = 'Ecoli Transformation'")[0]
		p = find(:item, { sample: { name: "SSJ128" } } )[0]
		t = Task.new(
			name: "test_jack", 
                	specification: { "plasmid_item_ids Plasmid Stock|1 ng/µL Plasmid Stock|Gibson Reaction Result" => [p.id] }.to_json, 
                	task_prototype_id: tp.id, 
        		status: "waiting", 
                	user_id: User.find_by_login("parks"),
                	budget_id: 1)
		t.save
		t.notify "Automatically created from Make E Comp Cells.", job_id: jid
		
	end
end
