## This protocol will return the location of item numbers and give an inventory, including location of sample numbers

needs "aqualib/lib/cloning"
needs "aqualib/lib/standard"

class Protocol

def arguments
    {
    #Enter the item numbers you wish to receive the location for 
    item_number: [],
    
    #Enter the sample numbers you wish to receive inventory for
    #sample_number: [3546, 3547, 3539]
    }
  end

def main 
	item_locations=[]
	item_numbers=input[:item_number]
	item_number_length=item_numbers.length
	
	#sample_numbers=input[:sample_number]
	#sample_number_length=sample_numbers.length
	
	count=0
	while count < item_number_length do
		temp=item_numbers[count]
		stock=find(:item, id: temp)
		temp1=stock[0].location
		
		item_locations[count]=temp1
		count=count+1
	end	
	
	show{
	  title "Here are the locations of the items specified"
	  table [["item", "location"]].concat(item_numbers.zip item_locations)
		}
end

end

  
