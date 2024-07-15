class RemoveIndexOnKindFromVisibilities < ActiveRecord::Migration[7.1]
  def change
    remove_index :visibilities, name: 'index_visibilities_on_kind'
  end
end
