class AddSpecialInstructionsToJudgingRounds < ActiveRecord::Migration[7.2]
  def change
    add_column :judging_rounds, :special_instructions, :text
  end
end
