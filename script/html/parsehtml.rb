# Proof of concept that we are able to parse customer RFQ emails

require 'nokogiri'

doc = Nokogiri::HTML(open("sample1.html"))
table = doc.at('table')
this_table = Array.new
table.search('tr').each do |tr|
  this_row = Array.new
  tr.search('td').each do |td|
    this_row << td.text.strip
  end
  this_table << this_row
end

puts this_table.inspect