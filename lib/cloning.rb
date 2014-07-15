module Cloning

  def fragment_info fid

    fragment = find(:sample,{id: fid})[0]# Sample.find(fid)
    props = fragment.properties

    fwd = props["Forward Primer"]
    rev = props["Reverse Primer"]
    template = props["Template"]

    if fwd == nil || rev == nil || template == nil

      return nil

    else

      fwd_items = fwd.in "Primer Aliquot"
      rev_items = rev.in "Primer Aliquot"
      template_items = template.in "Plasmid Stock"

      if fwd_items.length == 0 || rev_items.length == 0 || template_items.length == 0

        return nil

      else

        t1 = fwd_items[0].sample.properties["Tm Anneal"] || 70.0
        t2 = rev_items[0].sample.properties["Tm Anneal"] || 70.0

        return {
          fragment: fragment,
          fwd: fwd_items[0],
          rev: rev_items[0],
          template: template_items[0],
          tanneal: (t1+t2)/2.0
        }

      end

    end

  end

end
