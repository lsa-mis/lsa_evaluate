class RemoveStatusAssociations < ActiveRecord::Migration[7.2]
  def change
    # Remove status_id from ContestDescription
    remove_reference :contest_descriptions, :status, foreign_key: true, index: true

    # Remove status_id from ContestInstance
    remove_reference :contest_instances, :status, foreign_key: true, index: true

    # Remove status_id from Entry
    remove_reference :entries, :status, foreign_key: true, index: true
  end
end
