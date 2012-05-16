require 'spec_helper'
require 'jhove_service'

describe JhoveService do

  before :all do
    @fixtures = File.expand_path(File.dirname(__FILE__) + '/../fixtures')
    @bin_dir = File.expand_path(File.dirname(__FILE__) + '/../../bin')
    @content_dir = File.join(@fixtures,'test_files')
    @target_dir =  File.join(@fixtures,'target')
    Dir.mkdir(@target_dir) unless File.directory?(@target_dir)
    @jhove_service = JhoveService.new(@target_dir)
  end

  it "should have a target directory" do
    @jhove_service.target_pathname.should eql Pathname.new(@fixtures).join('target')
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
    tech_md_output = @jhove_service.create_technical_metadata(@jhove_service.jhove_output)
    #puts IO.read(tech_md_output)
    tech_xml = Nokogiri::XML(IO.read(tech_md_output))
    tech_xml.root.name.should eql('technicalMetadata')
    nodes = tech_xml.xpath('//file')
    nodes.size.should eql(3)
  end

  it "can do cleanup" do
    File.exist?(@jhove_service.jhove_output).should eql true
    File.exist?(@jhove_service.tech_md_output).should eql true
    @jhove_service.cleanup
    File.exist?(@jhove_service.jhove_output).should eql false
    File.exist?(@jhove_service.tech_md_output).should eql false
  end

end