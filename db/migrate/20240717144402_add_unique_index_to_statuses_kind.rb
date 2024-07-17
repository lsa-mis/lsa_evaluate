class AddUniqueIndexToStatusesKind < ActiveRecord::Migration[7.1]
  def change
    add_index :statuses, :kind, unique: true
  end
end
