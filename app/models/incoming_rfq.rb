# == Schema Information
#
# Table name: incoming_rfqs
#
#  id         :integer          not null, primary key
#  from       :string(255)
#  subject    :text
#  text_body  :text
#  html_body  :text
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class IncomingRfq < ActiveRecord::Base

  attr_accessible :from, :html_body, :subject, :text_body
  has_many :incoming_rfq_attachments, dependent: :destroy

end
