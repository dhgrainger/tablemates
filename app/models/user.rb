class User < ApplicationRecord
  include VenmoUsername

  has_secure_password
  has_many :sessions, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }
  normalizes :name, with: ->(n) { n.squish }

  validates :name, presence: true, length: { maximum: 60 }
  validates :email_address, presence: true, uniqueness: true,
    format: { with: URI::MailTo::EMAIL_REGEXP }, length: { maximum: 254 }
  validates :password, length: { minimum: 8 }, allow_nil: true
end
