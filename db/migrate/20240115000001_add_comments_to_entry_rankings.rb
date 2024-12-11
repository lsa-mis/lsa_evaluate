class AddCommentsToEntryRankings < ActiveRecord::Migration[7.2]
  def change
    add_column :entry_rankings, :internal_comments, :text
    add_column :entry_rankings, :external_comments, :text
  end
end
