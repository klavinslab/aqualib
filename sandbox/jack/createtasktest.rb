class Protocol
	
	def arguments
    		{
    		}
	 end
	
	def main
		tp = TaskPrototype.where("name = 'Ecoli Transformation'")[0]
		show {
			note tp
		}
		t = Task.new(name: "Ecoli_Transformation_#{aliquot_batch.id}", 
                specification: { "plasmid_item_ids Plasmid Stock|1 ng/µL Plasmid Stock|Gibson Reaction Result" => find(:item, { sample: { name: "SSJ128" } } )[0].id }.to_json, 
                task_prototype_id: tp.id, 
                status: "waiting", 
                user_id: Job.find(jid).user_id,
                budget_id: 1)
		t.save
		t.notify "Automatically created from Make E Comp Cells.", job_id: jid
	end
end
