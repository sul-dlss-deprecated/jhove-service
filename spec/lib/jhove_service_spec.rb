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

  specify "JhoveService#get_jhove_command" do
    jhove_cmd = @jhove_service.get_jhove_command(@content_dir)
    jhove_cmd.should == "/Users/rnanders/Code/Ruby/jhove-service/bin/jhoveToolkit.sh " +
        "edu.stanford.sulair.jhove.JhoveCommandLine " +
        "/Users/rnanders/Code/Ruby/jhove-service/spec/fixtures/test_files " +
        "> /Users/rnanders/Code/Ruby/jhove-service/spec/fixtures/target/jhove_output.xml"
    jhove_cmd = @jhove_service.get_jhove_command(@content_dir, "/my/fileset.txt")
    jhove_cmd.should == "/Users/rnanders/Code/Ruby/jhove-service/bin/jhoveToolkit.sh " +
        "edu.stanford.sulair.jhove.JhoveFileset " +
        "/Users/rnanders/Code/Ruby/jhove-service/spec/fixtures/test_files /my/fileset.txt " +
        "> /Users/rnanders/Code/Ruby/jhove-service/spec/fixtures/target/jhove_output.xml"
  end

  it "can run jhove against a directory" do
    jhove_output = @jhove_service.run_jhove(@content_dir)
    #puts IO.read(jhove_output)
    jhove_xml = Nokogiri::XML(IO.read(jhove_output))
    jhove_xml.root.name.should eql('jhove')
    nodes = jhove_xml.xpath('//jhove:repInfo', 'jhove' => 'http://hul.harvard.edu/ois/xml/ns/jhove')
    nodes.size.should eql(3)
  end

  it "can run jhove against a subset of files in a directory" do
    jhove_output = @jhove_service.run_jhove(@content_dir, File.join(@fixtures,'fileset.txt'))
    #puts IO.read(jhove_output)
    jhove_xml = Nokogiri::XML(IO.read(jhove_output))
    jhove_xml.root.name.should eql('jhove')
    nodes = jhove_xml.xpath('//jhove:repInfo', 'jhove' => 'http://hul.harvard.edu/ois/xml/ns/jhove')
    nodes.size.should eql(2)
  end

  it "should raise an exception if directory does not exist" do
     lambda{@jhove_service.run_jhove('/temp/dummy/@#')}.
         should raise_exception(%r{Error when running JHOVE against /temp/dummy/@#})
  end

  it "can create technical metadata" do
    jhove_output = @jhove_service.run_jhove(@content_dir)
    tech_md_output = @jhove_service.create_technical_metadata(jhove_output)
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