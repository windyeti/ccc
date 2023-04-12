class AddAmountToCategory < ActiveRecord::Migration[5.2]
  def change
    add_column :categories, :amount, :integer
  end
end
