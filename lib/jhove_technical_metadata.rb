require 'rubygems'
require 'nokogiri'
require 'time'

class JhoveTechnicalMetadata < Nokogiri::XML::SAX::Document

  def initialize(object_id)
    @digital_object_id = object_id
    @indent = 0
    #@ios = STDOUT #File.open(STDOUT, 'w')
  end

  def output(string)
    #@ios.
        puts "  "*@indent + string
  end

  def start_element(tag, attrs = [])
    case tag
      when 'jhove'
        root_open(attrs)
      when 'repInfo'
        file_wrapper_open(attrs)
      when 'properties'
        properties_open
      else
        if tag[0..2] == 'mix'
          mix_open(tag)
        elsif @in_jhove
          jhove_open(tag, attrs)
        end
    end
  end

  def characters(string)
    @text = string
  end

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
        end
    end
  end

  def root_open(attrs)
    output "<technicalMetadata objectId='#{@digital_object_id}' datetime='#{Time.now.utc.iso8601}'"
    @indent += 2
    output "xmlns:jhove='http://hul.harvard.edu/ois/xml/ns/jhove'"
    output "xmlns:mix='http://www.loc.gov/mix/v10'"
    output "xmlns:textmd='info:lc/xmlns/textMD-v3' >"
    @indent -= 1
  end

  def root_close
    @indent -= 1
    output "</technicalMetadata>"
  end

  def file_wrapper_open(attrs)
    filepath=nil
    attrs.each { |attr| filepath=attr[1] if attr[0]=='uri'}
    output "<file id='#{filepath}'>"
    @indent += 1
    @in_jhove = true
  end

  def file_wrapper_close
    case @format
      when 'HTML','TEXT','UTF-8'
        output_textmd('LF')
    end
    @indent -= 1
    output "</file>"
    @in_jhove = false
  end

  def jhove_open(tag, attrs)
     if @jhove_tag # saved previously
       output "<jhove:#{@jhove_tag}#{@jhove_attrs}>"
       @indent += 1
     end
     @jhove_tag = tag
     @jhove_attrs = ""
     attrs.each do |attr|
       @jhove_attrs += " #{attr[0]}='#{attr[1]}'"
     end
     @text = nil
   end

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
     a=1
   end

  def properties_open
    output "<jhove:properties>"
    @indent += 1
    @in_jhove = false
  end

  def properties_close
    @indent -= 1
    output "</jhove:properties>"
    @in_jhove = false
  end

  def mix_open(tag)
    if @mix_tag
      output "<#{@mix_tag}>"
      @indent += 1
    end
    @mix_tag = tag
    @text = nil
  end

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

  def output_textmd(linebreak)
    indent = @indent
    @indent = 0
    output <<-EOF
    <jhove:properties>
      <textmd:textMD>
        <textmd:character_info>
          <textmd:byte_order>big</textmd:byte_order>
          <textmd:byte_size>8</textmd:byte_size>
          <textmd:character_size>1</textmd:character_size>
          <textmd:linebreak>#{linebreak}</textmd:linebreak>
        </textmd:character_info>
        <textmd:pageOrder>left-to-right</textmd:pageOrder>
        <textmd:pageSequence>reading-order</textmd:pageSequence>
      </textmd:textMD>
    </jhove:properties>
    EOF
    @indent = indent
  end

end


#Create a parser
parser = Nokogiri::XML::SAX::Parser.new(JhoveTechnicalMetadata.new('druid:ab123cd4567'))
# Feed the parser some XML
fixtures = File.expand_path(File.dirname(__FILE__) + '/../fixtures')
parser.parse(File.open(File.join(fixtures,'jhove_output_426.xml'), 'rb'))