require 'simplecov'

SimpleCov.start do
  add_filter '/spec/'
  add_filter '/vendor/'
  
  add_group 'Core', 'lib/pllum'
  add_group 'HTTP', 'lib/pllum/http.rb'
  
  minimum_coverage 80
end