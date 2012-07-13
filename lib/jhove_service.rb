require 'nokogiri'
require 'pathname'
require 'jhove_technical_metadata'

class JhoveService

  # @return [Pathname] The directory in which program files are located
  attr_accessor :bin_pathname

  # @return [Pathname] The directory in which output should be generated
  attr_accessor :target_pathname

  # @return [String] The druid of the object, which gets inserted in the root element of the output
  attr_accessor :digital_object_id

  # @param [String] target_dir The  directory into which output should be generated
  def initialize(target_dir)
    @target_pathname = Pathname.new(target_dir)
    @bin_pathname = Pathname.new(File.expand_path(File.dirname(__FILE__) + '/../bin'))
  end

  # @return [String] The output file from the JHOVE run
  def jhove_output
    target_pathname.join('jhove_output.xml')
  end

  # @return [String] The technicalMetadata.xml output file path
  def tech_md_output
    target_pathname.join('technicalMetadata.xml')
  end

  # @param content_dir [String] the directory path containing the files to be analyzed by JHOVE
  # @param fileset_file [String] the pathname of the file listing which files should be processed.  If nil, process all files.
  # @return [String] Run JHOVE to characterize all content files, returning the output file path
  def run_jhove(content_dir, fileset_file=nil)
    `#{get_jhove_command(content_dir, fileset_file)}`
    exitcode = $?.exitstatus
    if (exitcode != 0)
      raise "Error when running JHOVE against #{content_dir}"
    end
    jhove_output.to_s
  end

  # @param content_dir [String] the directory path containing the files to be analyzed by JHOVE
  # @param fileset_file [String] the pathname of the file listing which files should be processed.  If nil, process all files.
  # @return [String] The jhove-toolkit command to be exectuted in a system call
  def get_jhove_command(content_dir, fileset_file=nil)
    if fileset_file.nil?
      args = "edu.stanford.sulair.jhove.JhoveCommandLine #{content_dir}"
    else
      args = "edu.stanford.sulair.jhove.JhoveFileset #{content_dir} #{fileset_file}"
    end
    jhove_script = bin_pathname.join('jhoveToolkit.sh').to_s
    jhove_cmd = "#{jhove_script} #{args} > #{jhove_output.to_s}"
    jhove_cmd
  end

  # @param [String] jhove_output The full path of the file containing JHOVE output to be transformed to technical metadata
  # @return [String] Convert jhove output it to technicalMetadata, returning the output file path
  def create_technical_metadata(output_file=jhove_output)
    output_pathname = Pathname.new(output_file)
    jhovetm = JhoveTechnicalMetadata.new()
    jhovetm.digital_object_id=@digital_object_id
    jhovetm.output_file=tech_md_output
    # Create a SAX parser
    parser = Nokogiri::XML::SAX::Parser.new(jhovetm)
    # Feed the parser some XML
    parser.parse(output_pathname.open('rb'))
    tech_md_output.to_s
  end

  # @return [void] Cleanup the temporary workspace used to hold the metadata outputs
  def cleanup()
    jhove_output.delete if jhove_output.exist?
    tech_md_output.delete if tech_md_output.exist?
  end

end