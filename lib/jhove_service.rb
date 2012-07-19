require 'nokogiri'
require 'pathname'
require 'jhove_technical_metadata'
require 'stringio'

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
    `#{get_jhove_command(content_dir, fileset_file)}`
    exitcode = $?.exitstatus
    if (exitcode != 0)
      raise "Error when running JHOVE against #{content_dir.to_s}"
    end
    jhove_output.to_s
  end

  # @param content_dir [Pathname,String] the directory path containing the files to be analyzed by JHOVE
  # @param fileset_file [Pathname,String] the pathname of the file listing which files should be processed.  If nil, process all files.
  # @return [String] The jhove-toolkit command to be exectuted in a system call
  def get_jhove_command(content_dir, fileset_file=nil)
    if fileset_file.nil?
      args = "edu.stanford.sulair.jhove.JhoveCommandLine #{content_dir.to_s}"
    else
      args = "edu.stanford.sulair.jhove.JhoveFileset #{content_dir.to_s} #{fileset_file.to_s}"
    end
    jhove_script = @bin_pathname.join('jhoveToolkit.sh').to_s
    jhove_cmd = "#{jhove_script} #{args} > #{jhove_output.to_s}"
    jhove_cmd
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