require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'jhove_service'
require 'nokogiri'

describe JhoveService do

  before :all do
    @fixtures = File.expand_path(File.dirname(__FILE__) + '/../fixtures')
    @bin_dir = File.expand_path(File.dirname(__FILE__) + '/../../bin')
    @content_dir = File.join(@fixtures,'test_files')
    @temp_dir =  File.join(@fixtures,'temp')
    @jhove_service = JhoveService.new(@temp_dir)
  end


  it "should have a temp directory" do
    @jhove_service.temp_dir.should eql(File.join(@fixtures,'temp'))
  end

  it "can generate a temp file path" do
    @jhove_service.temp_file('xyz').should eql(File.join(@temp_dir,'xyz'))
  end

  it "can generate a script file path" do
    @jhove_service.bin_file('abc').should eql(File.join(@bin_dir,'abc'))
  end

  it "can run jhove against a directory" do
    jhove_output = @jhove_service.run_jhove(@content_dir)
    #puts IO.read(jhove_output)
    jhove_xml = Nokogiri::XML(IO.read(jhove_output))
    jhove_xml.root.name.should eql('jhove')
    nodes = jhove_xml.xpath('//jhove:repInfo', 'jhove' => 'http://hul.harvard.edu/ois/xml/ns/jhove')
    nodes.size.should eql(3)
  end

  it "can create technical metadata" do
    tech_md = @jhove_service.create_technical_metadata(File.join(@fixtures,'jhove_output_426.xml'))
    #puts IO.read(tech_md)
    tech_xml = Nokogiri::XML(IO.read(tech_md))
    tech_xml.root.name.should eql('jhove')
    nodes = tech_xml.xpath('//jhove:repInfo', 'jhove' => 'http://hul.harvard.edu/ois/xml/ns/jhove')
    nodes.size.should eql(3)
  end

  it "can do cleanup" do
    jhove_output = File.join(@temp_dir,'jhove_output.xml')
    tech_md = File.join(@temp_dir,'technicalMetadata.xml')
    FileUtils.touch(jhove_output)
    File.exist?(jhove_output).should eql true
    FileUtils.touch(tech_md)
    File.exist?(tech_md).should eql true
    @jhove_service.cleanup
    File.exist?(jhove_output).should eql false
    File.exist?(tech_md).should eql false
  end

end