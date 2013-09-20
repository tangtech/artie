require "rubygems"
require "active_support"
require "bundler/setup"
require "gtk2"
require "poppler"
require "nokogiri"
require "net/smtp"
require "mailman"

require File.dirname(__FILE__) + "/../config/environment"
Mailman.config.ignore_stdin = true

Mailman.config.pop3 = {
    server: 'pop.gmail.com', port: 995, ssl: true,
    username: GMAIL_USERNAME,
    password: GMAIL_PASSWORD
}

SENDER_EMAIL_REGEX = /From:.*[\w+\-.]+@[a-z\d\-.]+\.[a-z]+/i

# Define the various Regex patterns expected for an Aker BOM
# Eventually, this part should be part of a dynamic include, depending on customer
BOM_REGEX = /MATERIAL REPORT/i
DWG_REGEX = /Aker/i
PART_NUMBER_REGEX = /Material\s*:(.*)/
DESCRIPTION_REGEX = /Description\s*:.*/
PART_REVISION_REGEX = /Revision Level\s*:.*/
DRAWING_REGEX = /Related Drawings\s*:.*/
PSL_REGEX = /PSL\s*:.*/i
TEMP_REGEX = /Temp\s*:.*/i
MATERIAL_CLASS_REGEX = /Class\s*:.*/i
PROCESSES_REGEX = /PROCESS SPECIFICATION\s*:.*/m
CUSTOMER_SPEC_REGEX1 = /(C|HT|MS|PS|QS|WS)-\d{3}( |-).*/i
CUSTOMER_SPEC_REGEX2 = /- - -.*/i
MATERIAL_SPEC_REGEX1 = /MS-\d{3}( |-).*/i
MATERIAL_SPEC_REGEX2 = /.*MATERIAL REQUIREMENT.*/i
MATERIAL_SPEC_REGEX3 = /.*ALTERNATE MATERIAL.*/i
STAMPING_SPEC_REGEX = /PS-126.*/i
NDE_SPEC_REGEX1 = /PS-107.*/i
NDE_SPEC_REGEX2 = /PS-108.*/i

# Define the various Regex patterns expected for an Aker Drawing
# Eventually, this part should be part of a dynamic include, depending on customer
MATCH_DRAWING_REGEX = /\d{11}.*/
DRAWING_NUMBER_FORMAT_REGEX = /-\w{3}-/
ACME_THREAD_REGEX = /\d*\s?\d+\/?\d*-\d+ (ACME|NA|STUB ACME|SA)-\d\w(-LH)?/i
API_THREAD_REGEX = /\d*\s?-?\d+\/?\d* (API IF|API LP|API UPTBG|IF[^C]|NPT|EU)/i
SHARPVEE_THREAD_REGEX = /SHARP VEE THD/i
UN_THREAD_REGEX = /\d*\s?\d+\/?\d*-\d+ (UN|UNC|UNF|UNS)-\d\w/i
DIMENSION_INCHES_REGEX = /dimensions are in inches/i
DIMENSION_MM_REGEX = /dimensions are in mm/i
WEIGHT_REGEX = /\d+\.?\d* (LBS|KG)/i

Mailman::Application.run do
  default do
    begin
      # Extract email body & sender
      the_message_html = (message.multipart? ? message.html_part.body.decoded.force_encoding("ISO-8859-1").encode("UTF-8")  : message.body.decoded.force_encoding("ISO-8859-1").encode("UTF-8"))
      the_message_text = (message.multipart? ? message.text_part.body.decoded.force_encoding("ISO-8859-1").encode("UTF-8")  : message.body.decoded.force_encoding("ISO-8859-1").encode("UTF-8"))
      the_message_subject = message.subject.gsub /Fwd: /, ''
      the_message_sender = message.from.first

      # If email sender does not match a customer domain...
      if Customer.where(:domain => message.from.first.split("@")[1]).count == 0
        # Regex match who has forwarded it...
        # Note: This Regex ONLY matches the formatting used in Gmail's 'Forward', not 'Reply'
        this_message_sender_matches = the_message_text.scan(SENDER_EMAIL_REGEX)
        # And loop until (i) we get a match or (ii) run out of matches
        i = 0
        while the_message_sender == message.from.first && !this_message_sender_matches[i].nil? do
          the_message_sender = this_message_sender_matches[i].to_s.split("<")[1] if Customer.where(:domain => this_message_sender_matches[i].to_s.split("@")[1]).count > 0
          i += 1
        end
      end

      # Only add to our database if a valid customer is identified
      if Customer.where(:domain => the_message_sender.split("@")[1]).count > 0
        @incoming_rfq = IncomingRfq.create(:from => message.from.first, :originator => the_message_sender, :subject => the_message_subject, :html_body => the_message_html, :text_body => the_message_text)

        # Extract and save attachments
        if message.multipart?
          message.attachments.each do |attachment|
            file = StringIO.new(attachment.decoded)
            file.class.class_eval { attr_accessor :original_filename, :content_type }
            file.original_filename = attachment.filename
            file.content_type = attachment.mime_type
            # Our system can only handle TXT and PDF file formats for now
            if file.content_type == "text/plain" || file.content_type == "application/pdf"
              incoming_rfq_attachment = IncomingRfqAttachment.new
              incoming_rfq_attachment.attached_file = file
              incoming_rfq_attachment.incoming_rfq_id = @incoming_rfq.id
              incoming_rfq_attachment.save
            end
          end
        end

        # Extract list of items from HTML table in email
        # This only works for the Aker Batam BO format
        # KIV extract to another file and called dynamically after introducing functionality for other customer formats
        doc = Nokogiri::HTML(the_message_html)
        table = doc.at('table')
        this_table = []
        table.search('tr').each do |tr|
          this_row = []
          tr.search('td').each do |td|
            this_row << td.text.strip
          end
          this_table << this_row
        end

        # Get indices for :part_number, :description, :quantity, :required_delivery_date
        index_part_number = this_table[0].index("Material")
        index_description = this_table[0].index("Short Text")
        index_quantity = this_table[0].index("Qty")
        index_required_delivery_date = this_table[0].index("Delivery")
        this_table.shift

        # Store :part_number, :required_delivery_date in arrays
        get_all_dates = []
        get_all_part_numbers = []
        this_table.each do |row|
          get_all_dates << row[index_required_delivery_date]
          get_all_part_numbers << row[index_part_number]
        end

        # Check if :required_delivery_date is formatted DD/MM/YYYY or MM/DD/YYYY
        get_valid_dates = get_all_dates.select { |date| Date.parse(date) rescue nil }
        incoming_rfq_american_date = (get_all_dates.count != get_valid_dates.count ? true : nil)

        # Get unique :part_number...
        get_valid_part_numbers  = get_all_part_numbers.uniq
        get_valid_part_numbers.each do |part_number|
          incoming_rfq_item = IncomingRfqItem.new
          incoming_rfq_item.incoming_rfq_id = @incoming_rfq.id
          incoming_rfq_item.part_number = part_number
          incoming_rfq_item.quantity = 0
          this_table.each do |row|
            # Match :description, :quantity, :required_delivery_date...
            if part_number == row[index_part_number]
              incoming_rfq_item.quantity += row[index_quantity].to_i
              incoming_rfq_item.description = row[index_description]
              this_date = (incoming_rfq_american_date.nil? ? Date.strptime(row[index_required_delivery_date], "%d/%m/%Y") : Date.strptime(row[index_required_delivery_date], "%m/%d/%Y"))
              incoming_rfq_item.required_delivery_date = this_date if incoming_rfq_item.required_delivery_date.nil? || incoming_rfq_item.required_delivery_date > this_date
            end
          end
          # And save it to our DB
          puts incoming_rfq_item.inspect
          incoming_rfq_item.save

          # Search for matching attachments and extract text
          match_attachments = IncomingRfqAttachment.where("attached_file_file_name LIKE (?)", "#{part_number}%")
          match_attachments.each do |matched_attachment|
            input_text = ''
            if matched_attachment.attached_file_content_type == "text/plain"
              input_text = File.read(matched_attachment.attached_file.path)
            elsif matched_attachment.attached_file_content_type == "application/pdf"
              doc = Poppler::Document.new(matched_attachment.attached_file.path)
              doc.each do |page|
                input_text.concat page.get_text if !page.get_text.strip.nil?
              end
              if input_text == ''
                basepath = matched_attachment.attached_file.path
                basepath = basepath.split("/")
                filepath = basepath.join("\\")
                basepath.pop
                basepath = basepath.join("\\")

                # Split multi-page PDF files
                if doc.n_pages == 1
                  IO.popen("copy #{filepath} #{basepath}\\pg_1.pdf") {|f| $stderr.puts "#{f} 1-page PDF file"}
                else
                  IO.popen("pdftk #{filepath} burst output #{basepath}\\pg_%1d") {|f| $stderr.puts "#{f} Split PDF file"}
                  File.delete("#{basepath}\\doc_data.txt")
                end
                # Run through OCR engine
                doc.each do |page|
                  this_page = page.index + 1
                  direction = ["North", "South", "East", "West"]
                  direction.each do |direction|
                    IO.popen("pdftk #{basepath}\\pg_#{this_page}.pdf cat 1-end#{direction} output #{basepath}\\pg_#{this_page}#{direction}.pdf") {|f| $stderr.puts "#{f} Rotate #{direction}"}
                    IO.popen("gswin64c -dSAFER -dNOPAUSE -dBATCH -q -r300 -sDEVICE=pnggray -sOutputFile=#{basepath}\\pg_#{this_page}#{direction}.png #{basepath}\\pg_#{this_page}#{direction}.pdf") {|f| $stderr.puts "#{f} Orientation #{direction}: Convert to 300dpi PNG"}
                    IO.popen("tesseract #{basepath}\\pg_#{this_page}#{direction}.png #{basepath}\\pg_#{this_page}#{direction}") {|f| $stderr.puts "#{f} Orientation #{direction}: OCR"}
                    input_text.concat File.read("#{basepath}\\pg_#{this_page}#{direction}.txt")
                    File.delete("#{basepath}\\pg_#{this_page}#{direction}.png")
                    File.delete("#{basepath}\\pg_#{this_page}#{direction}.txt")
                    File.delete("#{basepath}\\pg_#{this_page}#{direction}.pdf")
                  end
                  File.delete("#{basepath}\\pg_#{this_page}.pdf") # Remove unwanted files created by the PDF split
                end
              end
            end

            # Test whether it is a BOM or DWG
            if BOM_REGEX.match(input_text)
              matched_part_number = PART_NUMBER_REGEX.match(input_text).to_s.split(":")[1].to_s.strip
              matched_part_revision = PART_REVISION_REGEX.match(input_text).to_s.split(":")[1].to_s.split(";")[0].to_s.strip

              # Verify that BOM matches :part_number & does not exist in DB
              if part_number == matched_part_number
                if Part.where(:part_number => matched_part_number, :part_revision => matched_part_revision).count == 0
                  # Create new record
                  this_part = Part.new
                  this_part.customer_domain = the_message_sender.split("@")[1]
                  this_part.part_number = matched_part_number
                  this_part.part_revision = matched_part_revision

                  this_part.description = DESCRIPTION_REGEX.match(input_text).to_s.split(":")[1].to_s.strip
                  this_part.part_ecn = PART_REVISION_REGEX.match(input_text).to_s.split(":")[1].to_s.split(";")[1].to_s.strip
                  this_part.drawing_number = DRAWING_REGEX.match(input_text).to_s.split(":")[3].to_s.split(",")[0].to_s.strip
                  this_part.drawing_revision = DRAWING_REGEX.match(input_text).to_s.split(":")[4].to_s.split(",")[0].to_s.strip
                  this_part.psl = PSL_REGEX.match(input_text).to_s.split(":")[1].to_s.split(" ")[0].to_s.strip
                  this_part.material_temperature = TEMP_REGEX.match(input_text).to_s.split(":")[1].to_s.split(" ")[0].to_s.strip
                  this_part.material_class = MATERIAL_CLASS_REGEX.match(input_text).to_s.split(":")[1].to_s.strip

                  this_part.material_specification_short = []
                  this_part.material_specification_full = []
                  this_part.process_specification_short = []
                  this_part.process_specification_full = []
                  this_part.stamping_specification_full = []
                  this_part.stamping_specification_psl = false

                  this_process = nil
                  processes = PROCESSES_REGEX.match(input_text).to_s.split(/\r?\n/)

                  # Extract the specified processes
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

                    unless BOM_REGEX.match(line)
                      if this_process == 'material'
                        this_part.material_specification_short << MATERIAL_SPEC_REGEX1.match(line).to_s.split(" ")[0]
                        this_part.material_specification_full << this_line
                      end
                      if this_process == 'nde' || this_process == 'other'
                        this_part.process_specification_short << CUSTOMER_SPEC_REGEX1.match(line).to_s.split(" ")[0]
                        this_part.process_specification_full << this_line
                      end
                      if this_process == 'stamping'
                        if /PS-126 STAMP DATE \(MO/i.match(line)
                          this_process = nil
                          this_part.stamping_specification_psl = true
                        else
                          this_part.stamping_specification_full << this_line
                        end
                      end
                    end
                  end

                  this_part.stamping_type = this_part.stamping_specification_full[0].split(" ")[1]

                  this_part.attached_bom = matched_attachment.attached_file

                  puts this_part.inspect
                  this_part.save

                  # Commented out for now. To include at the user verification stage
                  # Stamping info for BBW82546S2​E37 is ok on its own, but gets truncated in the array! No idea why.
                  # this_part.stamping_information = this_part.stamping_specification_full.join(" ")
                  # this_part.stamping_information = this_part.stamping_information.gsub /PSL \d/, '\0 (MO/YR)' if this_part.stamping_specification_psl
                  # this_part.stamping_information = this_part.stamping_information.split(":")
                  # this_part.stamping_information.shift
                  # this_part.stamping_information = this_part.stamping_information.join(":").strip
                  # puts this_part.stamping_information.inspect

                else
                  puts "This Part Number has already been created"
                end
              else
                puts "BOM does not match Part Number"
              end
            elsif DWG_REGEX.match(input_text)

              drawing_number = MATCH_DRAWING_REGEX.match(input_text).to_s
              matched_drawing_number = (DRAWING_NUMBER_FORMAT_REGEX.match(drawing_number) ? drawing_number.to_s.split("-")[0].to_s.strip : drawing_number.to_s.split(" ")[0].to_s.strip)
              matched_drawing_revision = (DRAWING_NUMBER_FORMAT_REGEX.match(drawing_number) ? drawing_number.to_s.split(" ")[0].to_s.split("-")[3].to_s.strip : drawing_number.to_s.split(" ")[1].to_s.strip)

              # Verify that Drawing does not exist in DB
              if Drawing.where(:drawing_number => matched_drawing_number, :drawing_revision => matched_drawing_revision).count == 0
                this_drawing = Drawing.new
                this_drawing.drawing_number = matched_drawing_number
                this_drawing.drawing_revision = matched_drawing_revision

                this_drawing.threads = []
                input_text.to_s.split(/\r?\n/).each do |line|
                  this_drawing.threads << ACME_THREAD_REGEX.match(line).to_s.strip if ACME_THREAD_REGEX.match(line)
                  this_drawing.threads << API_THREAD_REGEX.match(line).to_s.strip if API_THREAD_REGEX.match(line)
                  this_drawing.threads << SHARPVEE_THREAD_REGEX.match(line).to_s.strip if SHARPVEE_THREAD_REGEX.match(line)
                  this_drawing.threads << UN_THREAD_REGEX.match(line).to_s.strip if UN_THREAD_REGEX.match(line)
                end
                this_drawing.threads.uniq!

                this_drawing.dimension_unit = "inches" if DIMENSION_INCHES_REGEX.match(input_text)
                this_drawing.dimension_unit = "mm" if DIMENSION_MM_REGEX.match(input_text)

                # To be implemented: Use size and density to double-check if weight is reasonable
                this_drawing.weight = WEIGHT_REGEX.match(input_text).to_s.split(" ")[0].to_s.strip
                this_drawing.weight_unit = WEIGHT_REGEX.match(input_text).to_s.split(" ")[1].to_s.strip

                this_drawing.customer_domain = the_message_sender.split("@")[1]
                this_drawing.attached_drawing = matched_attachment.attached_file

                puts this_drawing.inspect
                this_drawing.save

              end
            end
          end
        end

        # Else, send an error email if cannot upload
      else
        email_body = <<END_OF_MESSAGE
From: New RFQ Uploader <new.rfq@tangtechnical.com>
To: <#{message.from.first}>
Subject: Error Uploading #{message.subject}
Your Email #{message.subject} could not be uploaded.
END_OF_MESSAGE

        smtp = Net::SMTP.new 'smtp.gmail.com', 587
        smtp.enable_starttls
        smtp.start('gmail.com', GMAIL_USERNAME, GMAIL_PASSWORD, :login)
        smtp.send_message email_body, 'new.rfq@tangtechnical.com', message.from.first
        smtp.finish
      end

    rescue Exception => e
      Mailman.logger.error "Exception occurred while receiving message:\n#{message}"
      Mailman.logger.error [e, *e.backtrace].join("\n")
    end
  end
end
