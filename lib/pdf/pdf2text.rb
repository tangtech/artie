require "gtk2"
require "poppler"

input_uri = "BB1.pdf"
input_text = ''

doc = Poppler::Document.new(input_uri)
doc.each { |page| input_text.concat page.get_text } # Should only match pages with "MATERIAL REPORT" header

PART_NUMBER_REGEX = /Material\s*:(.*)/
DESCRIPTION_REGEX = /Description\s*:.*/
PART_REVISION_REGEX = /Revision Level\s*:.*/
DRAWING_REGEX = /Related Drawings\s*:.*/
PSL_REGEX = /PSL\s*:.*/i
TEMP_REGEX = /Temp\s*:.*/i
MATERIAL_CLASS_REGEX = /Class\s*:.*/i
PROCESSES_REGEX = /PROCESS SPECIFICATION\s*:.*/m
CUSTOMER_SPEC_REGEX1 = /[A-Z]{1,2}-\d{3}.*/i
CUSTOMER_SPEC_REGEX2 = /- - -.*/i
MATERIAL_SPEC_REGEX1 = /MS-\d{3}.*/i
MATERIAL_SPEC_REGEX2 = /.*MATERIAL REQUIREMENT.*/i
MATERIAL_SPEC_REGEX3 = /.*ALTERNATE MATERIAL.*/i
STAMPING_SPEC_REGEX = /PS-126.*/i
NDE_SPEC_REGEX1 = /PS-107.*/i
NDE_SPEC_REGEX2 = /PS-108.*/i

part = {}
part["part_number"] = PART_NUMBER_REGEX.match(input_text).to_s.split(":")[1].to_s.strip
part["description"] = DESCRIPTION_REGEX.match(input_text).to_s.split(":")[1].to_s.strip
part["part_revision"] = PART_REVISION_REGEX.match(input_text).to_s.split(":")[1].to_s.split(";")[0].to_s.strip
part["part_ecn"] = PART_REVISION_REGEX.match(input_text).to_s.split(":")[1].to_s.split(";")[1].to_s.strip
part["drawing_number"] = DRAWING_REGEX.match(input_text).to_s.split(":")[3].to_s.split(",")[0].to_s.strip
part["drawing_revision"] = DRAWING_REGEX.match(input_text).to_s.split(":")[4].to_s.split(",")[0].to_s.strip
part["psl"] = PSL_REGEX.match(input_text).to_s.split(":")[1].to_s.split(" ")[0].to_s.strip
part["material_temperature"] = TEMP_REGEX.match(input_text).to_s.split(":")[1].to_s.split(" ")[0].to_s.strip
part["material_class"] = MATERIAL_CLASS_REGEX.match(input_text).to_s.split(":")[1].to_s.strip

part["material_specification_short"] = []
part["material_specification_full"] = []
part["process_specification_short"] = []
part["process_specification_full"] = []
part["stamping_specification_full"] = []

this_process = nil
processes = PROCESSES_REGEX.match(input_text).to_s.split(/\r?\n/)

processes.each do |line|
  if CUSTOMER_SPEC_REGEX1.match(line) || CUSTOMER_SPEC_REGEX2.match(line)
    this_process = 'other'
    this_process = 'material' if MATERIAL_SPEC_REGEX1.match(line) || MATERIAL_SPEC_REGEX2.match(line) || MATERIAL_SPEC_REGEX3.match(line)
    this_process = 'stamping' if STAMPING_SPEC_REGEX.match(line)
    this_process = 'nde' if NDE_SPEC_REGEX1.match(line) || NDE_SPEC_REGEX2.match(line)
    this_line = (CUSTOMER_SPEC_REGEX1.match(line) ? CUSTOMER_SPEC_REGEX1.match(line).to_s.strip : CUSTOMER_SPEC_REGEX2.match(line).to_s.strip )
  else
    this_process = nil if this_process == 'other'
    this_line = line.to_s.strip
  end

  if this_process == 'material'
    part["material_specification_short"] << MATERIAL_SPEC_REGEX1.match(line).to_s.split(" ")[0]
    part["material_specification_full"] << this_line
  end
  if this_process == 'nde' || this_process == 'other'
    part["process_specification_short"] << CUSTOMER_SPEC_REGEX1.match(line).to_s.split(" ")[0]
    part["process_specification_full"] << this_line
  end
  if this_process == 'stamping'
    part["stamping_specification_full"] << this_line
  end
end

part["stamping_type"] = part["stamping_specification_full"][0].split(" ")[1]
part["stamping_information"] = part["stamping_specification_full"].join(" ").split(":")
part["stamping_information"].shift
part["stamping_information"] = part["stamping_information"].join(":").strip

puts part
