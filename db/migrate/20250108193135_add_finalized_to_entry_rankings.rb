class AddFinalizedToEntryRankings < ActiveRecord::Migration[7.2]
  def change
    add_column :entry_rankings, :finalized, :boolean, null: false, default: false
  end
end
