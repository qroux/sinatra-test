class Comment < ActiveRecord::Base
  belongs_to :post

  validates :content, :post_id, presence: true
end
