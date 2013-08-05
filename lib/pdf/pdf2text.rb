#!/usr/bin/env ruby

require "gtk2"
require "poppler"

input_uri = "BB2.pdf"
parsetext = ''

doc = Poppler::Document.new(input_uri)
doc.each { |page| parsetext.concat page.get_text }

PART_NUMBER_REGEX = /Material\s*:(.*)/
DESCRIPTION_REGEX = /Description\s*:.*/
PART_REVISION_REGEX = /Revision Level\s*:.*/
DRAWING_REGEX = /Related Drawings\s*:.*/
PSL_REGEX = /PSL\s*:.*/i
TEMP_REGEX = /Temp\s*:.*/i
MATERIAL_CLASS_REGEX = /Class\s*:.*/i
PROCESSES_REGEX = /PROCESS SPECIFICATION\s*:.*Characteristics/m
AKER_SPEC_REGEX = /\w{1,2}-\d{3}(.*)/i

puts PART_NUMBER_REGEX.match(parsetext).to_s.split(":")[1].to_s.strip
puts DESCRIPTION_REGEX.match(parsetext).to_s.split(":")[1].to_s.strip
puts PART_REVISION_REGEX.match(parsetext).to_s.split(":")[1].to_s.split(";")[0].to_s.strip
puts DRAWING_REGEX.match(parsetext).to_s.split(":")[3].to_s.split(",")[0].to_s.strip
puts DRAWING_REGEX.match(parsetext).to_s.split(":")[4].to_s.split(",")[0].to_s.strip
puts PSL_REGEX.match(parsetext).to_s.split(":")[1].to_s.split(" ")[0].to_s.strip
puts TEMP_REGEX.match(parsetext).to_s.split(":")[1].to_s.split(" ")[0].to_s.strip
puts MATERIAL_CLASS_REGEX.match(parsetext).to_s.split(":")[1].to_s.strip

processes = PROCESSES_REGEX.match(parsetext).to_s.split(/\r?\n/)
processes.each do |line|
  if AKER_SPEC_REGEX.match(line)
    puts AKER_SPEC_REGEX.match(line).to_s.strip
  else
    puts line.to_s.strip
  end
end
