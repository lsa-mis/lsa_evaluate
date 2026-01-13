class AddInstructionsSentAtToRoundJudgeAssignments < ActiveRecord::Migration[7.2]
  def change
    add_column :round_judge_assignments, :instructions_sent_at, :datetime
  end
end
