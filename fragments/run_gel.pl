require "aqualib:lib/util.pl"
require "aqualib:lib/cloning.pl"

argument
  FO: generic
end

print("Input to Run Gel", FO )

log
  return: { FO: FO }
end
