class AddCommentRequirementsToContestInstances < ActiveRecord::Migration[7.2]
  def change
    add_column :contest_instances, :require_internal_comments, :boolean, default: false, null: false
    add_column :contest_instances, :require_external_comments, :boolean, default: false, null: false
    add_column :contest_instances, :min_internal_comment_words, :integer, default: 0, null: false
    add_column :contest_instances, :min_external_comment_words, :integer, default: 0, null: false
  end
end
