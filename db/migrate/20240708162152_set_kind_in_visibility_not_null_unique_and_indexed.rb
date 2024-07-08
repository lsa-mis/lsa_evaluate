class SetKindInVisibilityNotNullUniqueAndIndexed < ActiveRecord::Migration[7.1]
  def change
    change_column_null :visibilities, :kind, false
    add_index :visibilities, :kind, unique: true
  end
end
