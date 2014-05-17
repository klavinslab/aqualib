Fragments Object
================

All protocols, except pcr.pl, in the fragment build pipeline take a fragements object as input. All protocols return a fragments object as output. The object is specifed in json. Not all protocols operate on all parts of the object. The protocol pcr.pl is generates the initial object, which subsequent protocols add to.

	{

		"fragments": [
			{ 
				fragment_id: 0,
				forward_primer_id: 0,
				reverse_primer_id: 0,
				gel_box_id: 0,
				gel_lane: 0,
				fragment_stock_id: 0
			},
			...
		],

                "stripwells": [ 0, ... ]

	}