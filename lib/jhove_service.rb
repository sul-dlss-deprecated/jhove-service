require 'nokogiri'
require 'pathname'
require 'jhove_technical_metadata'

class JhoveService

  # @return [String] The directory in which program files are located
  attr_accessor :bin_pathname

  # @return [String] The directory in which output should be generated
  attr_accessor :target_pathname

  # @return [String] The output file from the JHOVE run
  attr_accessor :jhove_output

  # @return [String] The technicalMetadata.xml output file path
  attr_accessor :tech_md_output

  # @return [String] The druid of the object, which gets inserted in the root element of the output
  attr_accessor :digital_object_id

  # @param [String] target_dir The  directory into which output should be generated
  def initialize(target_dir)
    @target_pathname = Pathname.new(target_dir)
    @bin_pathname = Pathname.new(File.expand_path(File.dirname(__FILE__) + '/../bin'))
  end

  # @param [String] content_dir the directory path containing the files to be analyzed by JHOVE
  # @return [String] Run JHOVE to characterize all content files, returning the output file path
  def run_jhove(content_dir)
    @jhove_output = target_pathname.join('jhove_output.xml')
    jhove_script = bin_pathname.join('jhoveToolkit.sh').to_s
    `#{jhove_script} #{content_dir} > #{@jhove_output.to_s}`
    exitcode = $?.exitstatus
    if (exitcode != 0)
      raise "Error when running JHOVE against #{content_dir}"
    end
    @jhove_output.to_s
  end

  # @param [String] jhove_output The full path of the file containing JHOVE output to be transformed to technical metadata
  # @return [String] Convert jhove output it to technicalMetadata, returning the output file path
  def create_technical_metadata(jhove_output=@jhove_output.to_s)
    @tech_md_output = target_pathname.join('technicalMetadata.xml')
    jhovetm = JhoveTechnicalMetadata.new()
    jhovetm.digital_object_id=@digital_object_id
    jhovetm.output_file=@tech_md_output
    # Create a SAX parser
    parser = Nokogiri::XML::SAX::Parser.new(jhovetm)
    # Feed the parser some XML
    parser.parse(File.open(jhove_output, 'rb'))
    @tech_md_output.to_s
  end

  # @deprecated
  # Convert jhove output it to technicalMetadata
  def create_technical_metadata_old(jhove_output)
    tech_md = target_pathname.join('technicalMetadata.xml').to_s
    xslt = bin_file('jhove-filter.xsl')
    transform(jhove_output, tech_md, xslt)
    tech_md
  end

  # @deprecated
  # Perform a generic file to file transform on local system
  # @param [String, String, String, String]
  def transform(input, output, xslt, params=nil)
    xslt_script = bin_file('xslt_transform.sh')
    if params
      `#{xslt_script} #{input} #{output} #{xslt} #{params}`
    else
      `#{xslt_script} #{input} #{output} #{xslt}`
    end
    exitcode = $?.exitstatus
    if (exitcode != 0)
      raise "Error when transforming #{input} to #{output} using #{xslt}"
    end
    output
  end

  # @return [void] Cleanup the temporary workspace used to hold the metadata outputs
  def cleanup()
    @jhove_output.delete if @jhove_output.exist?
    @tech_md_output.delete if @tech_md_output.exist?
  end

end