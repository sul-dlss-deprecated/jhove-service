$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require 'rubygems'
require 'rspec'
require 'rspec/matchers' # req by equivalent-xml custom matcher `be_equivalent_to`
require 'equivalent-xml'

def count_nodes(jhove_xml)
  jhove_xml.xpath('//jhove:repInfo', 'jhove' => 'http://hul.harvard.edu/ois/xml/ns/jhove').size
end

def count_errors(jhove_xml)
  jhove_xml.css('//repInfo/messages/message[@severity="error"]').size
end

RSpec.configure do |config|

end
