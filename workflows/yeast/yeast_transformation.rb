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
      stripwell_ids: [],
      yeast_transformed_strain_ids: [1705,1706,1879]
    }
  end

  def main
  	yeast_competent_cells = input[:yeast_competent_ids].collect {|yid| find(:item, id: yid )[0]}
    yeast_transformation_mixtures = input[:yeast_transformed_strain_ids].collect {|yid| produce new_sample find(:sample, id: yid)[0].name, of: "Yeast Strain", as: "Yeast Transformation Mixture"}

    show {
      title "Testing page"
      note(yeast_competent_cells.collect {|x| x.id})
      note(yeast_transformation_mixtures.collect {|x| x.id})
    }

    return input.merge yeast_transformation_mixture_ids: yeast_transformation_mixtures.collect {|x| x.id}

  end

end
