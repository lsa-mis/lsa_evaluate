class RenameJudgingRoundsToTotalJudgingRoundsCount < ActiveRecord::Migration[7.2]
  def change
    rename_column :contest_instances, :judging_rounds, :total_judging_rounds_count
  end
end
