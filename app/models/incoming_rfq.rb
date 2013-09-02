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
#  originator :string(255)
#

class IncomingRfq < ActiveRecord::Base

  attr_accessible :from, :html_body, :originator, :subject, :text_body
  has_many :incoming_rfq_attachments, dependent: :destroy
  has_many :incoming_rfq_items, dependent: :destroy

  before_save do |incoming_rfq|
    incoming_rfq.from = from.downcase
    incoming_rfq.originator = originator.downcase
  end

  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  validates :from, presence: true, format: { with: VALID_EMAIL_REGEX }
  validates :originator, presence: true, format: { with: VALID_EMAIL_REGEX }

  default_scope order: 'incoming_rfqs.created_at DESC'

end
