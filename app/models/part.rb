# == Schema Information
#
# Table name: parts
#
#  id                           :integer          not null, primary key
#  customer_domain              :string(255)
#  part_number                  :string(255)
#  part_revision                :string(255)
#  part_ecn                     :string(255)
#  drawing_number               :string(255)
#  drawing_revision             :string(255)
#  description                  :string(255)
#  psl                          :string(255)
#  material_temperature         :string(255)
#  material_class               :string(255)
#  material_specification_short :text
#  material_specification_full  :text
#  process_specification_short  :text
#  process_specification_full   :text
#  stamping_specification_full  :text
#  stamping_specification_psl   :boolean
#  stamping_type                :string(255)
#  stamping_information         :string(255)
#  attached_bom_file_name       :string(255)
#  attached_bom_content_type    :string(255)
#  attached_bom_file_size       :integer
#  attached_bom_updated_at      :datetime
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#

class Part < ActiveRecord::Base

  attr_accessible :attached_bom, :customer_domain, :description, :drawing_number, :drawing_revision, :material_class, :material_specification_full, :material_specification_short, :material_temperature, :part_ecn, :part_number, :part_revision, :process_specification_full, :process_specification_short, :psl, :stamping_information, :stamping_specification_full, :stamping_specification_psl, :stamping_type
  has_attached_file :attached_bom
  serialize :material_specification_short
  serialize :material_specification_full
  serialize :process_specification_short
  serialize :process_specification_full
  serialize :stamping_specification_full

  before_save { |part| part.customer_domain = customer_domain.downcase }

  VALID_DOMAIN_REGEX = /[a-z\d\-.]+\.[a-z]+\z/i
  validates :customer_domain, presence: true, format: { with: VALID_DOMAIN_REGEX }
  validates :part_number, presence: true, length: { maximum: 100 }

end
