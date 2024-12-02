class RemoveTotalJudgingRoundsCountFromContestInstances < ActiveRecord::Migration[7.2]
  def change
    remove_column :contest_instances, :total_judging_rounds_count, :integer
  end
end
