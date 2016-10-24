class Protocol

  def main

    num_friends = 6

    show do
      title "Friendship"
      note "I have #{num_friends} friends!"
    end
  
  

    people_to_high_five = ["Michelle", "Eric", "Alberto", "David", "Ayesha"]
    foo = [0, 4, 6]
    show do
      note people_to_high_five[2]
    end

    show do
      title "High five checklist"
      people_to_high_five.each do |person|
        check "Give #{person} a high five"
      end
    end



    superpowers = { 
      clark: "heat vision", 
      diana: "whip", 
      barry: "super speed", 
      wade: "snark",
      bruce: "none" 
    }

    show do
      title "The best superpower"
      note "As far as superpowers go, even #{superpowers[:clark]} is " +
           "better than #{superpowers[:bruce]}."
    end
    
    return {}
    
  end

end
