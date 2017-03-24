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

  after :each do
    @jhove_service.cleanup
  end

  after :all do
    @temp.rmtree if @temp.exist?
  end

  it "should have a target directory" do
    expect(@jhove_service.target_pathname).to eq @fixtures.join('temp')
  end

  it "produces the correct get_jhove_command" do
    jhove_cmd = @jhove_service.get_jhove_command(@content_dir)
    expect(jhove_cmd).to eq "#{@bin.join('jhoveToolkit.sh')} -h xml -o \"#{@temp.join('jhove_output.xml')}\" \\\"#{@fixtures.join('test_files')}"
    jhove_cmd = @jhove_service.get_jhove_command(@content_dir,'/some/custom/output.xml')
    expect(jhove_cmd).to eq "#{@bin.join('jhoveToolkit.sh')} -h xml -o \"/some/custom/output.xml\" \\\"#{@fixtures.join('test_files')}"
  end

  it "can run jhove against a directory" do
    jhove_output = @jhove_service.run_jhove(@content_dir.join('audio'))
    jhove_xml = Nokogiri::XML(IO.read(jhove_output))
    expect(jhove_xml.root.name).to eq('jhove')
    expect(count_nodes(jhove_xml)).to eq(2)
    expect(count_errors(jhove_xml)).to eq(0)
    expect(jhove_xml.xpath('//jhove:repInfo/@uri', 'jhove' => 'http://hul.harvard.edu/ois/xml/ns/jhove')[0].content).to eq('Blue%20Square.wav') # path names should be relative
    expect(jhove_xml.xpath('//jhove:repInfo/@uri', 'jhove' => 'http://hul.harvard.edu/ois/xml/ns/jhove')[1].content).to eq('harmonica.mp3')
  end

  it "can run jhove against a list of files in a directory" do
    jhove_output = @jhove_service.run_jhove(@content_dir, @fixtures.join('fileset.txt'))
    jhove_xml = Nokogiri::XML(IO.read(jhove_output))
    expect(jhove_xml.root.name).to eq('jhove')
    files_in_set = 6
    expect(count_nodes(jhove_xml)).to eq(files_in_set)
    expect(count_errors(jhove_xml)).to eq(0)
    jhove_xml.xpath('//jhove:repInfo/@uri', 'jhove' => 'http://hul.harvard.edu/ois/xml/ns/jhove').each do |filename_node|
      expect(filename_node.content.include?(@content_dir.to_s)).to be_falsey # path names should be relative
    end
    for i in 0..files_in_set-1
      expect(File.exists?(@jhove_service.target_pathname.join("jhove_output_#{i}.xml"))).to be_falsey # it cleans up the temp files it created
    end
  end

  it "should raise an exception if directory or file list passed to run_jhove does not exist" do
     expect(lambda{@jhove_service.run_jhove('/temp/dummy/@#')}).to raise_exception(%r{Content /temp/dummy/@# not found})
     expect(lambda{@jhove_service.run_jhove(@content_dir,'/my/fileset.txt')}).to raise_exception(%r{File list /my/fileset.txt not found})
  end

  it "should raise an exception if the filelist exists but has no files in it" do
     expect(lambda{@jhove_service.run_jhove(@content_dir,@fixtures.join('empty_fileset.txt'))}).to raise_exception("File list #{@fixtures.join('empty_fileset.txt')} empty")
  end

  it "can create technical metadata" do
    jhove_output = @jhove_service.run_jhove(@content_dir, @fixtures.join('fileset.txt'))
    tech_md_output = @jhove_service.create_technical_metadata(jhove_output)
    tech_xml = Nokogiri::XML(IO.read(tech_md_output))
    expect(tech_xml.root.name).to eq('technicalMetadata')
    nodes = tech_xml.xpath('//file')
    expect(nodes.size).to eq(6)
  end

  specify "JhoveService#upgrade_technical_metadata" do
    old_tm_file = @samples.join('technicalMetadata-old.xml')
    new_tm = @jhove_service.upgrade_technical_metadata(old_tm_file.read)
    expected_tm = @samples.join('technicalMetadata.xml').read
    expect(new_tm.gsub(/datetime='.*?'/,'')).to be_equivalent_to expected_tm.gsub(/datetime='.*?'/,'')
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
    expect(new_tm.gsub(/datetime='.*?'/,'')).to be_equivalent_to(expected_tm.gsub(/datetime='.*?'/,''))
  end


  it "can do cleanup" do
    File.open(@jhove_service.jhove_output, "w") {}
    File.open(@jhove_service.tech_md_output, "w") {}
    expect(File.exist?(@jhove_service.jhove_output)).to be_truthy
    expect(File.exist?(@jhove_service.tech_md_output)).to be_truthy
    @jhove_service.cleanup
    expect(File.exist?(@jhove_service.jhove_output)).to be_falsey
    expect(File.exist?(@jhove_service.tech_md_output)).to be_falsey
  end

end
