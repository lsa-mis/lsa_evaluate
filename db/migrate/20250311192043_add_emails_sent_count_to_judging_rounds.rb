class AddEmailsSentCountToJudgingRounds < ActiveRecord::Migration[7.2]
  def change
    add_column :judging_rounds, :emails_sent_count, :integer, default: 0, null: false
  end
end
