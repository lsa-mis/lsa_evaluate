class AddBooleanFieldsToModels < ActiveRecord::Migration[7.2]
  def change
    # Add active and archived to ContestDescription
    add_column :contest_descriptions, :active, :boolean, default: false, null: false
    add_column :contest_descriptions, :archived, :boolean, default: false, null: false

    # Add active and archived to ContestInstance
    add_column :contest_instances, :active, :boolean, default: false, null: false
    add_column :contest_instances, :archived, :boolean, default: false, null: false

    # Add disqualified and deleted to Entry
    add_column :entries, :disqualified, :boolean, default: false, null: false
    add_column :entries, :deleted, :boolean, default: false, null: false
  end
end
