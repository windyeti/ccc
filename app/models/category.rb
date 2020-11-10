class Category < ApplicationRecord
  belongs_to :boss, class_name: 'Category', optional: true
  has_many :subordinates, class_name: 'Category', foreign_key: 'boss_id'

  validates :name, :link, :category_path, presence: true
end
