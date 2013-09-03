# == Schema Information
#
# Table name: drawings
#
#  id                            :integer          not null, primary key
#  customer_domain               :string(255)
#  drawing_number                :string(255)
#  drawing_revision              :string(255)
#  shape                         :string(255)
#  round_outside_diameter        :float
#  round_inside_diameter         :float
#  round_length                  :float
#  flat_length                   :float
#  flat_width                    :float
#  flat_thickness                :float
#  dimension_unit                :string(255)
#  weight                        :float
#  weight_unit                   :string(255)
#  threads                       :text
#  attached_drawing_file_name    :string(255)
#  attached_drawing_content_type :string(255)
#  attached_drawing_file_size    :integer
#  attached_drawing_updated_at   :datetime
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#

class Drawing < ActiveRecord::Base

  attr_accessible :attached_drawing, :customer_domain, :dimension_unit, :drawing_number, :drawing_revision, :flat_length, :flat_thickness, :flat_width, :round_inside_diameter, :round_length, :round_outside_diameter, :shape, :threads, :weight, :weight_unit
  has_attached_file :attached_drawing
  serialize :threads

  before_save { |drawing| drawing.customer_domain = customer_domain.downcase }

  VALID_DOMAIN_REGEX = /[a-z\d\-.]+\.[a-z]+\z/i
  validates :customer_domain, presence: true, format: { with: VALID_DOMAIN_REGEX }
  validates :drawing_number, presence: true, length: { maximum: 100 }

end
