# == Schema Information
#
# Table name: customers
#
#  id         :integer          not null, primary key
#  name       :string(255)
#  short_name :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  domain     :string(255)
#  branch     :string(255)
#

class Customer < ActiveRecord::Base

  attr_accessible :branch, :domain, :name, :short_name

  before_save { |customer| customer.domain = domain.downcase }

  VALID_DOMAIN_REGEX = /[a-z\d\-.]+\.[a-z]+\z/i
  validates :domain, presence: true, format: { with: VALID_DOMAIN_REGEX }
  validates :name, presence: true, length: { maximum: 100 }
  validates :short_name, presence: true, length: { maximum: 25 }
  validates :branch, presence: true, length: { maximum: 25 }

end
