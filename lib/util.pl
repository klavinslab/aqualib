#########################################################################################
# Arrays
#

function array_same ( x, n )

  # builds an array of length n with all elements equal to x
  #
  # For example, array_same(0,3) returns [ 0, 0, 0 ]

  if n == 1
    return [ x ]
  else
    return concat ( [ x ], array_same ( x, n-1 ) )
  end 
end

function drop_column ( m, j )

  # returns a matrix m' that is the same as m but with column j removed

  local a = transpose(m)
  return transpose(concat(take(a,0,j),take(a,j+1,length(a)-j-1)))

end

#########################################################################################
# Arrays of hashes
#

function ha_select(list,key)

  # Takes a list of hashes and a key and returns and array of the values associated 
  # with that key in each hash.
  #
  # For example, ha_select([{a:1, b:2},{a:3,b:4}],:a) returns [ 1, 3 ]

  f = []
  foreach x in list
    f = append(f,x[key])
  end

  return f

end

function ha_get(list,key,value)

  # Takes a list of hashes and a key,value pair. Returns the last hash h such
  # that h[key] = value.
  #
  # For example, ha_get({a:1, b:2},{a:3,b:4}],:a,1) returns { a:1, b:2 }

  h = {}

  foreach x in list
    if x[key] == value
      h = x
    end
  end

  return h

end

#############################################################################################
# Producing 
#

function produce_multiple(container,sample_names)

  # Produces a new item for each sample name and returns the resulting items in an array
  #
  # For example, produce_multiple("Primer Aliquot",["P1","P2"])

  local result = []
  local p

  foreach name in sample_names

    produce silently 
      i = 1 container of name
    end

    result = append(result,i)

  end

  return result

end

#############################################################################################
# Convenience 
#

function print(description, message)

  step
    description: description
    note: message
  end

end

function die(message)

  step
    description: "Error!"
    warning: message
  end

  stop

end

