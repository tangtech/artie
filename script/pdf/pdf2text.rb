# Proof of concept that we are able to parse customer BOMs
# It will need to be called by the email retrieval script

require "gtk2"
require "poppler"

input_uri = "BB14.pdf"
input_bom_text = ''
input_drawing_text = ''

# Define the various Regex patterns expected for an Aker BOM
BOM_REGEX = /MATERIAL REPORT/i
DWG_REGEX = /(Aker|Kvaerner)/i
PART_NUMBER_REGEX = /Material\s*:(.*)/
DESCRIPTION_REGEX = /Description\s*:.*/
PART_REVISION_REGEX = /Revision Level\s*:.*/
DRAWING_REGEX = /Related Drawings\s*:.*/
PSL_REGEX = /PSL\s*:.*/i
TEMP_REGEX = /Temp\s*:.*/i
MATERIAL_CLASS_REGEX = /Class\s*:.*/i
PROCESSES_REGEX = /PROCESS SPECIFICATION\s*:.*Characteristics/m
CUSTOMER_SPEC_REGEX1 = /(C|CS|HT|MS|PS|QS|WS)-\d{3,4}.*/i
CUSTOMER_SPEC_REGEX2 = /- - -.*/i
MATERIAL_SPEC_REGEX1 = /MS-\d{3,4}.*/i
MATERIAL_SPEC_REGEX2 = /.*MATERIAL REQUIREMENT.*/i
MATERIAL_SPEC_REGEX3 = /.*ALTERNATE MATERIAL.*/i
STAMPING_SPEC_REGEX = /PS-126.*/i
NDE_SPEC_REGEX1 = /PS-107.*/i
NDE_SPEC_REGEX2 = /PS-108.*/i

part = {}
drawing = {}

# Split up multi-page PDF files
doc = Poppler::Document.new(input_uri)
if doc.n_pages == 1
  IO.popen("copy #{input_uri} pg_1.pdf") {|f| $stderr.puts "#{f} 1-page PDF file"}
else
  IO.popen("pdftk #{input_uri} burst output pg_%1d.pdf") {|f| $stderr.puts "#{f} Split PDF file"}
  File.delete("doc_data.txt")
end

doc.each do |page|
  this_page = page.index + 1
  if BOM_REGEX.match(page.get_text) # Use Poppler's built-in functions to extract PDF text and see if it's a BOM...
    input_bom_text.concat page.get_text
  elsif DWG_REGEX.match(page.get_text) # If it's a drawing with machine-readable PDF text...
    input_drawing_text.concat page.get_text
  else # Or a flattened PDF file that needs to be converted to PNG and run through the OCR engine
    this_page = page.index + 1
    direction = ["North", "South", "East", "West"]
    direction.each do |direction|
      IO.popen("pdftk pg_#{this_page}.pdf cat 1-end#{direction} output pg_#{this_page}#{direction}.pdf") {|f| $stderr.puts "#{f} Page #{this_page} Rotate #{direction}"}
      IO.popen("gswin64c -dSAFER -dNOPAUSE -dBATCH -q -r300 -sDEVICE=pnggray -sOutputFile=pg_#{this_page}#{direction}.png pg_#{this_page}#{direction}.pdf") {|f| $stderr.puts "#{f} Orientation #{direction}: Convert to 300dpi PNG"}
      IO.popen("tesseract pg_#{this_page}#{direction}.png pg_#{this_page}#{direction}") {|f| $stderr.puts "#{f} Orientation #{direction}: OCR"}
      input_drawing_text.concat File.read("pg_#{this_page}#{direction}.txt")
      File.delete("pg_#{this_page}#{direction}.png")
      File.delete("pg_#{this_page}#{direction}.txt")
      File.delete("pg_#{this_page}#{direction}.pdf")
    end
    drawing["ocr_warning"] = true
  end
  File.delete("pg_#{this_page}.pdf") # Remove unwanted files created by the PDF split
end

# Use Regex matching to extract the relevant strings for an Aker BOM
part["part_number"] = PART_NUMBER_REGEX.match(input_bom_text).to_s.split(":")[1].to_s.strip
part["description"] = DESCRIPTION_REGEX.match(input_bom_text).to_s.split(":")[1].to_s.strip
part["part_revision"] = PART_REVISION_REGEX.match(input_bom_text).to_s.split(":")[1].to_s.split(";")[0].to_s.strip
part["part_ecn"] = PART_REVISION_REGEX.match(input_bom_text).to_s.split(":")[1].to_s.split(";")[1].to_s.strip
part["drawing_number"] = DRAWING_REGEX.match(input_bom_text).to_s.split(":")[3].to_s.split(",")[0].to_s.strip
part["drawing_revision"] = DRAWING_REGEX.match(input_bom_text).to_s.split(":")[4].to_s.split(",")[0].to_s.strip
part["psl"] = PSL_REGEX.match(input_bom_text).to_s.split(":")[1].to_s.split(" ")[0].to_s.strip
part["material_temperature"] = TEMP_REGEX.match(input_bom_text).to_s.split(":")[1].to_s.split(" ")[0].to_s.strip
part["material_class"] = MATERIAL_CLASS_REGEX.match(input_bom_text).to_s.split(":")[1].to_s.strip

part["material_specification_short"] = []
part["material_specification_full"] = []
part["process_specification_short"] = []
part["process_specification_full"] = []
part["stamping_specification_full"] = []
part["stamping_specification_psl"] = false

this_process = nil
processes = PROCESSES_REGEX.match(input_bom_text).to_s.split(/\r?\n/)

# Slightly more complicated rules needed to extract the specified processes
processes.each do |line|
  puts line
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
  puts this_process

  if this_process == 'material'
    part["material_specification_short"] << MATERIAL_SPEC_REGEX1.match(line).to_s.split(" ")[0]
    part["material_specification_full"] << this_line
  end

  if this_process == 'nde' || this_process == 'other'
    if CUSTOMER_SPEC_REGEX2.match(line)
      part["process_specification_short"] << line.to_s.split("- - - ")[1]
      part["process_specification_full"] << this_line
    else
      part["process_specification_short"] << CUSTOMER_SPEC_REGEX1.match(line).to_s.split(" ")[0]
      part["process_specification_full"] << this_line
    end
  end

  if this_process == 'stamping'
    if /PS-126 STAMP DATE \(MO/i.match(line)
      this_process = nil
      part["stamping_specification_psl"] = true
    elsif /MATERIAL REPORT/i.match(line)
    else
      part["stamping_specification_full"] << this_line
    end
  end

end

# Bug: The following lines break the script if no BOM
part["stamping_type"] = part["stamping_specification_full"][0].split(" ")[1]
part["stamping_information"] = part["stamping_specification_full"].join(" ").split(":")
part["stamping_information"].shift
part["stamping_information"] = part["stamping_information"].join(":").strip
part["stamping_information"] = part["stamping_information"].gsub /PSL \d/, '\0 (MO/YR)' if part["stamping_specification_psl"]

# Ensure that the drawing matches the BOM
MATCH_DRAWING_REGEX = /#{part["drawing_number"]}.*/
DRAWING_NUMBER_FORMAT_REGEX = /-\w{3}-/
match_drawing_number = MATCH_DRAWING_REGEX.match(input_drawing_text).to_s
if DRAWING_NUMBER_FORMAT_REGEX.match(match_drawing_number)
  drawing["drawing_number"] = match_drawing_number.to_s.split("-")[0].to_s.strip
  drawing["drawing_revision"] = match_drawing_number.to_s.split(" ")[0].to_s.split("-")[3].to_s.strip.gsub("/","")
else
  drawing["drawing_number"] = match_drawing_number.to_s.split(" ")[0].to_s.strip
  drawing["drawing_revision"] = match_drawing_number.to_s.split(" ")[1].to_s.strip.gsub("/","")
end
puts "ERROR: Drawing Mismatch" if part["drawing_number"]!=drawing["drawing_number"] || part["drawing_revision"]!=drawing["drawing_revision"]

# Define the various Regex patterns expected for specified threads
drawing["threads"] = []
ACME_THREAD_REGEX = /\d*\s?\d+\/?\d*-\d+ (ACME|NA|STUB ACME|SA)-\d\w(-LH)?/i
API_THREAD_REGEX1 = /\d*\s?-?\d+\/?\d* (API LP|NPT)/i
API_THREAD_REGEX2 = /\d*\s?-?\d+\/\d+ (API IF|API UPTBG|IF[^C]|NC-\d{2}|EU)/i
SHARPVEE_THREAD_REGEX = /SHARP VEE THD/i
UN_THREAD_REGEX = /\d*\s?\d+\/?\d*-\d+ (UN|UNC|UNF|UNS)-\d\w/i

input_drawing_text.to_s.split(/\r?\n/).each do |line|
  drawing["threads"] << ACME_THREAD_REGEX.match(line).to_s.strip if ACME_THREAD_REGEX.match(line)
  drawing["threads"] << API_THREAD_REGEX1.match(line).to_s.strip if API_THREAD_REGEX1.match(line)
  drawing["threads"] << API_THREAD_REGEX2.match(line).to_s.strip if API_THREAD_REGEX2.match(line)
  drawing["threads"] << SHARPVEE_THREAD_REGEX.match(line).to_s.strip if SHARPVEE_THREAD_REGEX.match(line)
  drawing["threads"] << UN_THREAD_REGEX.match(line).to_s.strip if UN_THREAD_REGEX.match(line)
end
drawing["threads"].uniq!

# Check dimension units
DIMENSION_INCHES_REGEX = /dimensions are in inches/i
DIMENSION_MM_REGEX = /dimensions are in mm/i
drawing["dimension_unit"] = "inches" if DIMENSION_INCHES_REGEX.match(input_drawing_text)
drawing["dimension_unit"] = "mm" if DIMENSION_MM_REGEX.match(input_drawing_text)

# Check weight
# To be implemented: Use size and density to double-check if weight is reasonable
WEIGHT_REGEX = /\d+\.?\d* (LBS|KG)/i
drawing["weight"] = WEIGHT_REGEX.match(input_drawing_text).to_s

puts part
puts drawing