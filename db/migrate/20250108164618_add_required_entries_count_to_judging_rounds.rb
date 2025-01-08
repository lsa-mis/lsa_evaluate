class AddRequiredEntriesCountToJudgingRounds < ActiveRecord::Migration[7.2]
  def change
    add_column :judging_rounds, :required_entries_count, :integer, null: false, default: 0
  end
end
