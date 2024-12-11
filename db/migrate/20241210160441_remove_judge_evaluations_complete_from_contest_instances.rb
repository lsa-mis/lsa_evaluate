class RemoveJudgeEvaluationsCompleteFromContestInstances < ActiveRecord::Migration[7.2]
  def change
    remove_column :contest_instances, :judge_evaluations_complete, :boolean
  end
end
