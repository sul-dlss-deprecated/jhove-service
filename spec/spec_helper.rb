$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require 'rubygems'
require 'rspec'
require 'rspec/matchers' # req by equivalent-xml custom matcher `be_equivalent_to`
require 'equivalent-xml'

RSpec.configure do |config|

end
