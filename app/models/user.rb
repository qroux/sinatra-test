class User < ActiveRecord::Base
  has_many :posts, dependent: :destroy
  has_many :votes, dependent: :destroy

  validates :username, presence: true
end
