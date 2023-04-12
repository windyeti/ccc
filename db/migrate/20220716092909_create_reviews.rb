class CreateReviews < ActiveRecord::Migration[5.2]
  def change
    create_table :reviews do |t|
      t.string :title
      t.string :text
      t.string :author
      t.string :rating
      t.string :date
      t.string :date_published
      t.string :item_reviewed
      t.references :tov, foreign_key: true

      t.timestamps
    end
  end
end
