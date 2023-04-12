class CreateImages < ActiveRecord::Migration[5.2]
  def change
    create_table :images do |t|
      t.string :old_url
      t.string :new_url
      t.string :name

      t.timestamps
    end
  end
end
