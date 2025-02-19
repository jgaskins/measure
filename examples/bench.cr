require "crunits"
require "measure/length"
require "benchmark"

value = nil

puts "Instantiation"
Benchmark.ips do |x|
  x.report "crunits" { value = Units::Measurement.new(1, "mile", :name) }
  x.report "measure" { value = 1.mile }
end

puts
puts "Arithmetic"
Benchmark.ips do |x|
  units_a = Units::Measurement.new(1, "mile", :name)
  units_b = Units::Measurement.new(1, "km", :symbol)
  measure_a = 1.mile
  measure_b = 1.km

  x.report "crunits" { value = units_a + units_b }
  x.report "measure" { value = measure_a + measure_b }
end

puts
puts "Conversion"
Benchmark.ips do |x|
  units = Units::Measurement.new(1, "mile", :name)
  measure = 1.mile

  x.report "crunits" { value = units.convert_to "km", :symbol }
  x.report "measure" { value = measure.to :km }
end

puts value unless value
