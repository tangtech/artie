# == Schema Information
#
# Table name: incoming_rfq_attachments
#
#  id                         :integer          not null, primary key
#  attached_file_file_name    :string(255)
#  attached_file_content_type :string(255)
#  attached_file_file_size    :integer
#  attached_file_updated_at   :datetime
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  incoming_rfq_id            :integer
#

class IncomingRfqAttachment < ActiveRecord::Base

  attr_accessible :attached_file, :incoming_rfq_id

  has_attached_file :attached_file

  belongs_to :incoming_rfq

  validates :incoming_rfq_id, presence: true

end
