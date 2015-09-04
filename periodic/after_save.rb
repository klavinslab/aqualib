def after_save
  self.notify "Hello from after_save.rb: #{f 123}"
end

def f x
  x+1
end
