class RemoveJudgingOpenFromContestInstances < ActiveRecord::Migration[7.2]
  def change
    remove_column :contest_instances, :judging_open, :boolean
  end
end
