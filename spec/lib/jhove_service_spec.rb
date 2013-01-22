require 'spec_helper'
require 'jhove_service'

describe JhoveService do

  before :all do
    @bin = Pathname(File.dirname(__FILE__)).join('../../bin').realpath
    @fixtures = Pathname(File.dirname(__FILE__)).join('../fixtures').realpath
    @content_dir = @fixtures.join('test_files')
    @samples = @fixtures.join('samples')
    @temp =  @fixtures.join('temp')
    @temp.mkpath unless @temp.exist?
    @jhove_service = JhoveService.new(@temp.to_s)
  end

  after :all do
    @temp.rmtree if @temp.exist?
  end

  it "should have a target directory" do
    @jhove_service.target_pathname.should eql @fixtures.join('temp')
  end

  specify "JhoveService#get_jhove_command" do
    jhove_cmd = @jhove_service.get_jhove_command(@content_dir)
    jhove_cmd.should == @bin.join('jhoveToolkit.sh').to_s  +
        " edu.stanford.sulair.jhove.JhoveCommandLine " +
        @fixtures.join('test_files').to_s +
        " > " + @temp.join('jhove_output.xml').to_s
    jhove_cmd = @jhove_service.get_jhove_command(@content_dir, "/my/fileset.txt")
    jhove_cmd.should == @bin.join('jhoveToolkit.sh').to_s  +
        " edu.stanford.sulair.jhove.JhoveFileset " +
        @fixtures.join('test_files').to_s + " /my/fileset.txt" +
        " > " + @temp.join('jhove_output.xml').to_s
  end

  it "can run jhove against a directory" do
    jhove_output = @jhove_service.run_jhove(@content_dir.join('audio'))
    #puts IO.read(jhove_output)
    jhove_xml = Nokogiri::XML(IO.read(jhove_output))
    jhove_xml.root.name.should eql('jhove')
    nodes = jhove_xml.xpath('//jhove:repInfo', 'jhove' => 'http://hul.harvard.edu/ois/xml/ns/jhove')
    nodes.size.should eql(2)
  end

  it "can run jhove against a list of files in a directory" do
    jhove_output = @jhove_service.run_jhove(@content_dir, @fixtures.join('fileset.txt'))
    #puts IO.read(jhove_output)
    jhove_xml = Nokogiri::XML(IO.read(jhove_output))
    jhove_xml.root.name.should eql('jhove')
    nodes = jhove_xml.xpath('//jhove:repInfo', 'jhove' => 'http://hul.harvard.edu/ois/xml/ns/jhove')
    nodes.size.should eql(6)
  end

  it "should raise an exception if directory does not exist" do
     lambda{@jhove_service.run_jhove('/temp/dummy/@#')}.
         should raise_exception(%r{Error when running JHOVE against /temp/dummy/@#})
  end

  it "can create technical metadata" do
    jhove_output = @jhove_service.run_jhove(@content_dir, @fixtures.join('fileset.txt'))
    tech_md_output = @jhove_service.create_technical_metadata(jhove_output)
    #puts IO.read(tech_md_output)
    tech_xml = Nokogiri::XML(IO.read(tech_md_output))
    tech_xml.root.name.should eql('technicalMetadata')
    nodes = tech_xml.xpath('//file')
    nodes.size.should eql(6)
  end

  specify "JhoveService#upgrade_technical_metadata" do
    old_tm_file = @samples.join('technicalMetadata-old.xml')
    new_tm = @jhove_service.upgrade_technical_metadata(old_tm_file.read)
    expected_tm = @samples.join('technicalMetadata.xml').read
    new_tm.gsub(/datetime='.*?'/,'').should be_equivalent_to(expected_tm.gsub(/datetime='.*?'/,''))
  end

  specify "JhoveService#upgrade_technical_metadata for input with empty elements" do
    old_tm = <<-EOF
<?xml version="1.0" encoding="UTF-8"?>
<jhove xmlns="http://hul.harvard.edu/ois/xml/ns/jhove" xmlns:mix="http://www.loc.gov/mix/v10" xmlns:textmd="info:lc/xmlns/textMD-v3" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://hul.harvard.edu/ois/xml/ns/jhove http://cosimo.stanford.edu/standards/jhove/v1/jhove.xsd" name="JhoveToolkit" release="1.0" date="2009-08-06">
    <repInfo uri="contentMetadata.xml">
        <format>XML</format>
        <sigMatch>
            <module>XML-hul</module>
        </sigMatch>
        <mimeType>text/xml</mimeType>
        <checksums/>
    </repInfo>
</jhove>
    EOF
    new_tm = @jhove_service.upgrade_technical_metadata(old_tm)
    expected_tm = <<-EOF
<technicalMetadata
    xmlns:jhove='http://hul.harvard.edu/ois/xml/ns/jhove'
    xmlns:mix='http://www.loc.gov/mix/v10'
    xmlns:textmd='info:lc/xmlns/textMD-v3' >
  <file id='contentMetadata.xml'>
    <jhove:format>XML</jhove:format>
    <jhove:sigMatch>
      <jhove:module>XML-hul</jhove:module>
    </jhove:sigMatch>
    <jhove:mimeType>text/xml</jhove:mimeType>
    <jhove:checksums/>
  </file>
</technicalMetadata>
    EOF
    new_tm.gsub(/datetime='.*?'/,'').should be_equivalent_to(expected_tm.gsub(/datetime='.*?'/,''))
  end


  it "can do cleanup" do
    File.exist?(@jhove_service.jhove_output).should eql true
    File.exist?(@jhove_service.tech_md_output).should eql true
    @jhove_service.cleanup
    File.exist?(@jhove_service.jhove_output).should eql false
    File.exist?(@jhove_service.tech_md_output).should eql false
  end

end