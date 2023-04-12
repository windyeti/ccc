class CreateArticles < ActiveRecord::Migration[5.2]
  def change
    create_table :articles do |t|
      t.string :title
      t.string :anonce_image
      t.string :anonce_text
      t.string :anonce_data
      t.string :content
      t.string :mtitle
      t.string :mdesc
      t.string :mkeywords
      t.string :tags
      t.string :insales_link
      t.string :article_url

      t.timestamps
    end
  end
end
