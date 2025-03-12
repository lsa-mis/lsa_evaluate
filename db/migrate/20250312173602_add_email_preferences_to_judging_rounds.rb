class AddEmailPreferencesToJudgingRounds < ActiveRecord::Migration[7.2]
  def change
    add_column :judging_rounds, :include_average_ranking, :boolean, default: false
    add_column :judging_rounds, :include_advancement_status, :boolean, default: false
  end
end
