class AddUniqueIndexToCategoriesKind < ActiveRecord::Migration[7.1]
  def change
    add_index :categories, :kind, unique: true
  end
end
