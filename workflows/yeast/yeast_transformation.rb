needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  def debug
    true
  end

  def arguments
    {
      #input should be yeast competent cells and digested plasmids
      yeast_competent_ids: [8437,8431,8426],
      #stripwell that containing digested plasmids
      stripwell_ids: []
      transformed
    }
  end

  def main
  	yeast_competent_cells = []
  	input[:yeast_competent_ids:].each do |itd|
  		yeast_competent_cell = find(:item, id: itd)[0]
  		yeast_competent_cells.push yeast_competent_cells
  		name = yeast_competent_cells.sample.name
  		overnight = produce new_sample name, of: "Yeast Strain", as: "Yeast Transformation Mixture"
  		overnights.push overnight
  	end


end
