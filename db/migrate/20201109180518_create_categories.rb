class CreateCategories < ActiveRecord::Migration[5.2]
  def change
    create_table :categories do |t|
      t.references :boss, index: true
      t.string :name
      t.string :link
      t.string :url
      t.text :category_path
      t.string :image_from_up
      t.text :description_from_up
      t.string :image
      t.text :description
      t.text :sdesc
      t.text :mtitle
      t.text :mdesc
      t.text :mkeywords
      t.boolean :parsing, default: false

      t.timestamps
    end
  end
end
