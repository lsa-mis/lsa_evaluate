class RemoveCategoryIdFromContestInstances < ActiveRecord::Migration[7.2]
  def change
    remove_column :contest_instances, :category_id, :bigint
  end
end
