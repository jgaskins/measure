require "spec"

def be_within(epsilon, of value)
  be_close value, epsilon
end
