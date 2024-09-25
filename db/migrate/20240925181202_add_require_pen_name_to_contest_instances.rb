class AddRequirePenNameToContestInstances < ActiveRecord::Migration[7.2]
  def change
    add_column :contest_instances, :require_pen_name, :boolean, default: false, null: false
  end
end
