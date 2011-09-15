require 'nokogiri'
require 'fileutils'

class JhoveService

  attr_accessor :target_dir

  def initialize(target_dir)
    @target_dir = target_dir
  end

  def target_file(basename)
    File.join(@target_dir, basename)
  end

  def bin_file(basename)
    bin_dir = File.expand_path(File.dirname(__FILE__) + '/../bin')
    File.join(bin_dir, basename)
  end

    # Run JHOVE to characterize all content files
  def run_jhove(content_dir)
    jhove_output = target_file('jhove_output.xml')
    jhove_script = bin_file('jhoveToolkit.sh')
    `#{jhove_script} #{content_dir} > #{jhove_output}`
    exitcode = $?.exitstatus
    if (exitcode != 0)
      raise "Error when running JHOVE against #{content_dir}"
    end
    jhove_output
  end

    # Convert jhove output it to technicalMetadata
    def create_technical_metadata(jhove_output)
      tech_md = target_file('technicalMetadata.xml')
      xslt = bin_file('jhove-filter.xsl')
      transform(jhove_output, tech_md, xslt)
      tech_md
    end

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

  def cleanup()
    entry = target_file('jhove_output.xml')
    FileUtils.remove_entry(entry) if File.exist?(entry)
    entry = target_file('technicalMetadata.xml')
    FileUtils.remove_entry(entry) if File.exist?(entry)
  end

end