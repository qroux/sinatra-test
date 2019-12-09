class Post < ActiveRecord::Base
  belongs_to :user
  has_many :comments, dependent: :destroy
  has_many :votes, dependent: :destroy

  validates :title, :content, :user_id, presence: true
  validates :title, length: { maximum: 35 }
end
