require 'rubygems'
require 'nokogiri'
require 'time'
require 'pathname'

# A SAX handler for filtering JHOVE output to create a technicalMetadata datastream
# The previous mechanism (uising XSLT tranformation) was causing out of memory errors,
# due to XSLT's behavior of loading both the input and output objects into memory.
class JhoveTechnicalMetadata < Nokogiri::XML::SAX::Document

  def initialize()
    @indent = 0
    @ios = STDOUT #File.open(STDOUT, 'w')
  end

  # @return [String] The druid of the object, which gets inserted in the root element of the output
  attr_accessor :digital_object_id

  # @param [Pathname] pathname the location of the technicalMetadata.xml file to be created
  # @return [void] Opens the output stream pointing to the specified file
  def output_file=(pathname)
    @ios = pathname.open('w')
  end

  # @param [String] string The character string to be appended to the output
  # @return [void] Append the specified string to the output stream
  def output(string)
    @ios.puts "  "*@indent + string
  end

  # @param [String] tag the name of the XML element from the parsed input
  # @param [Hash] attrs the XML attributes of the element
  # @return [void] this method is called by the sax parser at the beginning of an element
  def start_element(tag, attrs = [])
    case tag
      when 'jhove'
        # <jhove> is the root element of the input
        root_open(attrs)
      when 'repInfo'
        # A <repInfo> element contains the data for each file
        file_wrapper_open(attrs)
      when 'properties'
        # A <properties> element contains the variable data for the file
        properties_open
      else
        if tag[0..2] == 'mix'
          # JHOVE output for image files contains tech md in MIX format that we copy verbatum to output
          mix_open(tag)
        elsif @in_jhove
          # we've encountered one of the JHOVE elements that we want to automatically copy
          jhove_open(tag, attrs)
        elsif @in_properties
          # we're looking for the LineEndings property in the JHOVE output
          linebreak_open(tag)
        end
    end
  end

  # @param [String] tag the value of a text node found in the parsed XML
  # @return [void] this method is called by the sax parser when a text node is encountered
  def characters(string)
    @text = string
  end

  # @param [String] tag the name of the XML element from the parsed input
  # @return [void] this method is called by the sax parser at the end of an element
  def end_element(tag)
    case tag
      when 'jhove'
        root_close
      when 'repInfo'
        file_wrapper_close
      when 'properties'
        properties_close
      else
        if tag[0..2] == 'mix'
          mix_close(tag)
        elsif @in_jhove
          jhove_close(tag)
        elsif @in_properties
          linebreak_close(tag)
        end
    end
  end

  # @param [Hash] attrs the attributes of the <jhove> element in the XML input
  # @return [void] create the <technicalMetadata> root element of the XML output and include namespace declararions
  def root_open(attrs)
    if @digital_object_id
      output "<technicalMetadata objectId='#{@digital_object_id}' datetime='#{Time.now.utc.iso8601}'"
    else
      output "<technicalMetadata datetime='#{Time.now.utc.iso8601}'"
    end
    @indent += 2
    output "xmlns:jhove='http://hul.harvard.edu/ois/xml/ns/jhove'"
    output "xmlns:mix='http://www.loc.gov/mix/v10'"
    output "xmlns:textmd='info:lc/xmlns/textMD-v3' >"
    @indent -= 1
  end

  # @return [void] add the closing element of the output document
  def root_close
    @indent -= 1
    output "</technicalMetadata>"
    @ios.close
  end

  # @param [Hash] attrs the attributes of the <jhove> element in the XML input
  # @return [void] Append a <file> element to the output, setting the id attribute to the file path
  def file_wrapper_open(attrs)
    filepath=nil
    attrs.each { |attr| filepath=attr[1] if attr[0]=='uri'}
    output "<file id='#{filepath}'>"
    @indent += 1
    @in_jhove = true
  end

  # @return [void] Append a </file> tag to close the file data,
  # but first inset a textMD stanza if the file has a text format
  def file_wrapper_close
    case @format
      when 'ASCII', 'HTML','TEXT','UTF-8'
        output_textmd(@linebreak)
    end
    @indent -= 1
    output "  </jhove:properties>" if @in_properties

    output "</file>"
    @in_jhove = false
    @in_properties=false
  end

  # @param [String] tag the name of the XML element from the parsed input
  # @param [Hash] attrs the attributes of the <jhove> element in the XML input
  # @return [void] Copy this jhove element tag and its attributes verbatum
  def jhove_open(tag, attrs)
     if @jhove_tag # saved previously
       # we encountered a new element so output what was previously cached
       output "<jhove:#{@jhove_tag}#{@jhove_attrs}>"
       @indent += 1
     end
     # cache the element name and its attributes
     @jhove_tag = tag
     @jhove_attrs = ""
     attrs.each do |attr|
       @jhove_attrs += " #{attr[0]}='#{attr[1]}'"
     end
     @text = nil
     @linebreak='LF'
   end

  # @param [String] tag the name of the XML element from the parsed input
   # @return [void] Output a closing tag, preceded by cached data, if such exists
   def jhove_close(tag)
     if @text && tag == @jhove_tag
       output "<jhove:#{@jhove_tag}#{@jhove_attrs}>#{@text}</jhove:#{tag}>"
     else
       @indent -=1
       output "</jhove:#{tag}>"
     end
     @format = @text if tag == 'format'
     @text = nil
     @jhove_tag = nil
     @jhove_attrs=""
   end

   # @return [void] Output a <properties> element if one was encountered in the input,
   #   then ignore most input data from within the properties element, except mix and LineBreaks
  def properties_open
    output "<jhove:properties>"
    @indent += 1
    @in_jhove = false
    @in_properties=true
  end

  # @return [void] Appending of a closing tag is handled elsewhere
  def properties_close
    @indent -= 1
  end

  # @param [String] tag the name of the XML element from the parsed input
  # @return [void] Copy any Mix data verbatum,
  def mix_open(tag)
    if @mix_tag
      # we encountered a new element so output what was previously cached
      output "<#{@mix_tag}>"
      @indent += 1
    end
     # cache the element name
    @mix_tag = tag
    @text = nil
  end

  # @param [String] tag the name of the XML element from the parsed input
  # @return [void] Output a closing tag, preceded by cached data, if such exists
  def mix_close(tag)
    if @text && tag == @mix_tag
      output "<#{tag}>#{@text}</#{tag}>"
    else
      @indent -=1
      output "</#{tag}>"
    end
    @text = nil
    @mix_tag = nil
  end

  # @param [String] tag the name of the XML element from the parsed input
  # @return [void] Keep clearing the text cache any time a new element is encountered
  def linebreak_open(tag)
    @text = nil if @text
  end

  # @param [String] tag the name of the XML element from the parsed input
  # @return [void] Look for the LineEndings name/value pair, which is spread across multiple elements
  def linebreak_close(tag)
    case tag
      when 'name'
        @in_line_endings = false
        @in_line_endings = true if @text == 'LineEndings'
      when 'value'
        @linebreak = @text if @in_line_endings
        @in_line_endings = false
    end
  end

  # @param [Object] linebreak the CRLF or LF value found in the JHOVE output ()default is LF)
  # @return [void] Output a textMD section within the properties element
  def output_textmd(linebreak)
    indent = @indent
    @indent = 0
    if @in_properties
      # properties element tags provided by other code
      output <<-EOF
      <textmd:textMD>
        <textmd:character_info>
          <textmd:byte_order>big</textmd:byte_order>
          <textmd:byte_size>8</textmd:byte_size>
          <textmd:character_size>1</textmd:character_size>
          <textmd:linebreak>#{linebreak}</textmd:linebreak>
        </textmd:character_info>
      </textmd:textMD>
      EOF
    else
      # there were no properties elements in the input, so we must supply them ourselves
      output <<-EOF
      <jhove:properties>
        <textmd:textMD>
          <textmd:character_info>
            <textmd:byte_order>big</textmd:byte_order>
            <textmd:byte_size>8</textmd:byte_size>
            <textmd:character_size>1</textmd:character_size>
            <textmd:linebreak>#{linebreak}</textmd:linebreak>
          </textmd:character_info>
        </textmd:textMD>
      </jhove:properties>
      EOF
    end
    @indent = indent
  end

end


# Below is the equivalent of a java main method.
# For this to work OK, the module/class being invoked
# must have already have been loaded by the Ruby interpreter.

if __FILE__ == $0
  # Create a handler
  jhovetm = JhoveTechnicalMetadata.new()
  jhovetm.digital_object_id=ARGV[0]
  jhovetm.output_file=Pahtname.new(ARGV[2])
  # Create a SAX parser
  parser = Nokogiri::XML::SAX::Parser.new(jhovetm)
  # Feed the parser some XML
  parser.parse(File.open(ARGV[1], 'rb'))
end
