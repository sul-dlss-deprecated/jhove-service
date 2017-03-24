require 'nokogiri'
require 'pathname'
require 'jhove_technical_metadata'
require 'stringio'
require 'uri'

  class JhoveService

  # @return [Pathname] The directory in which program files are located
  attr_accessor :bin_pathname

  # @return [Pathname] The directory in which output should be generated
  attr_accessor :target_pathname

  # @return [String] The druid of the object, which gets inserted in the root element of the output
  attr_accessor :digital_object_id

  # @param [String] target_dir The  directory into which output should be generated
  def initialize(target_dir=nil)
    @target_pathname = Pathname.new(target_dir) unless target_dir.nil?
    @bin_pathname = Pathname.new(File.expand_path(File.dirname(__FILE__) + '/../bin'))
  end

  # @return [String] The output file from the JHOVE run
  def jhove_output
    @target_pathname.join('jhove_output.xml')
  end

  # @return [String] The technicalMetadata.xml output file path
  def tech_md_output
    @target_pathname.join('technicalMetadata.xml')
  end

  # @param content_dir [Pathname,String] the directory path containing the files to be analyzed by JHOVE
  # @param fileset_file [Pathname,String] the pathname of the file listing which files should be processed.  If nil, process all files.
  # @return [String] Run JHOVE to characterize all content files, returning the output file path
  def run_jhove(content_dir, fileset_file=nil)
    raise "Content #{content_dir} not found" unless File.directory? content_dir
    if fileset_file.nil? # a simple directory gets called directly
      exec_command(get_jhove_command(content_dir))
      jhove_output_xml_ng = File.open(jhove_output) { |f| Nokogiri::XML(f) }
    else # a filelist gets run one by one, jhove cannot do this out of the box, so we need to run jhove file by file and then assemble the results ourselves into a single XML
      raise "File list #{fileset_file} not found" unless File.exists? fileset_file
      files = File.new(fileset_file).readlines
      raise "File list #{fileset_file} empty" if files.size == 0
      combined_xml_output = ""
      jhove_output_xml_ng = Nokogiri::XML('')
      files.each_with_index do |filename,i| # generate jhove output for each file in a separate xml file
        full_path_to_file = File.join(content_dir,filename.strip)
        output_file = @target_pathname.join("jhove_output_#{i}.xml")
        exec_command(get_jhove_command(full_path_to_file,output_file))
        jhove_output_xml_ng = File.open(output_file) { |f| Nokogiri::XML(f) }
        combined_xml_output += jhove_output_xml_ng.css("//repInfo").to_xml # build up an XML string with all output
        output_file.delete
      end
      jhove_output_xml_ng.root.children.each {|n| n.remove} # use all of the files we built up above, strip all the children to get the root jhove node
      jhove_output_xml_ng.root << combined_xml_output # now add the combined xml for all files
    end
    remove_path_from_file_nodes(jhove_output_xml_ng,content_dir)
    File.write(jhove_output, jhove_output_xml_ng.to_xml)
    jhove_output.to_s
  end

  # @param command [String] the command to execute on the command line
  # @return [String] exitcode, or raised exception if there is a problem
  def exec_command(command)
    `#{command}`
    exitcode = $?.exitstatus
    raise "Error when running JHOVE #{command}" if (exitcode != 0)
    exitcode
  end

  # @param content [Pathname,String] the directory path or filename containing the folder or file to be analyzed by JHOVE
  # @param output_file [Pathname,String] the output file to write the XML to, defaults to filename specified in jhove_output
  # @return [String] The jhove-toolkit command to be exectuted in a system call
  def get_jhove_command(content,output_file = jhove_output)
    args = "-h xml -o \"#{output_file}\" \\\"#{content}"
    jhove_script = @bin_pathname.join('jhoveToolkit.sh')
    jhove_cmd = "#{jhove_script} #{args}"
    jhove_cmd
  end

  # @param jhove_output_xml_ng [ng_xml_obj] the nokogiri xml output from jhove
  # @param path [String] the shared path that will be removed from each file name to ensure the file nodes are relative
  def remove_path_from_file_nodes(jhove_output_xml_ng,path)
    jhove_output_xml_ng.xpath('//jhove:repInfo', 'jhove' => 'http://hul.harvard.edu/ois/xml/ns/jhove').each do |filename_node|
      filename_node.attributes['uri'].value = URI.decode(filename_node.attributes['uri'].value.gsub("#{path}",'').sub(/^\//,'')) # decode and remove path and any leading /
    end
  end

  # @param [Pathname,String] jhove_pathname The full path of the file containing JHOVE output to be transformed to technical metadata
  # @return [String] Convert jhove output it to technicalMetadata, returning the output file path
  def create_technical_metadata(jhove_pathname=jhove_output)
    jhove_pathname = Pathname.new(jhove_pathname)
    jhovetm = JhoveTechnicalMetadata.new()
    jhovetm.digital_object_id=self.digital_object_id
    jhovetm.output_file=tech_md_output
    # Create a SAX parser
    parser = Nokogiri::XML::SAX::Parser.new(jhovetm)
    # Feed the parser some XML
    parser.parse(jhove_pathname.open('rb'))
    tech_md_output.to_s
  end

  # @param [String] old_tm the old techMD xml to be transformed to new technical metadata format
  # @return [String] Convert old techMD date to new technicalMetadata format
  def upgrade_technical_metadata(old_tm)
    new_tm = StringIO.new()
    upgrade_sax_handler = JhoveTechnicalMetadata.new()
    upgrade_sax_handler.digital_object_id=self.digital_object_id
    upgrade_sax_handler.ios = new_tm
    # Create a SAX parser
    parser = Nokogiri::XML::SAX::Parser.new(upgrade_sax_handler)
    # Feed the parser some XML
    parser.parse(old_tm)
    new_tm.string
  end


  # @return [void] Cleanup the temporary workspace used to hold the metadata outputs
  def cleanup()
    jhove_output.delete if jhove_output.exist?
    tech_md_output.delete if tech_md_output.exist?
  end

end
