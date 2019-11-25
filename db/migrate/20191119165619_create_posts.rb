class CreatePosts < ActiveRecord::Migration[6.0]
  def change
    create_table :posts do |t|
      t.string :title
      t.string :content
      t.string :photo
      t.integer :rating
      t.timestamps null: false
    end
  end
end
