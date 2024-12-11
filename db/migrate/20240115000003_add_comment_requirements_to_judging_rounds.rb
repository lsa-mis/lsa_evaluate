class AddCommentRequirementsToJudgingRounds < ActiveRecord::Migration[7.2]
  def change
    add_column :judging_rounds, :require_internal_comments, :boolean, default: false, null: false
    add_column :judging_rounds, :require_external_comments, :boolean, default: false, null: false
    add_column :judging_rounds, :min_internal_comment_words, :integer, default: 0, null: false
    add_column :judging_rounds, :min_external_comment_words, :integer, default: 0, null: false

    # Remove columns from contest_instances if they exist
    remove_column :contest_instances, :require_internal_comments, :boolean
    remove_column :contest_instances, :require_external_comments, :boolean
    remove_column :contest_instances, :min_internal_comment_words, :integer
    remove_column :contest_instances, :min_external_comment_words, :integer
  end
end
