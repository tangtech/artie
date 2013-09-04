# == Schema Information
#
# Table name: incoming_rfq_items
#
#  id                     :integer          not null, primary key
#  incoming_rfq_id        :integer
#  part_number            :string(255)
#  description            :string(255)
#  quantity               :integer
#  required_delivery_date :date
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  customer_material      :boolean          default(FALSE)
#

class IncomingRfqItem < ActiveRecord::Base

  attr_accessible :description, :incoming_rfq_id, :part_number, :quantity, :required_delivery_date
  belongs_to :incoming_rfq

  validates :incoming_rfq_id, presence: true

end
