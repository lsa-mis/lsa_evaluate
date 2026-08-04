# frozen_string_literal: true

class CreateContestInvitations < ActiveRecord::Migration[8.1]
  def change
    create_table :contest_invitations do |t|
      t.references :contest_instance, null: false, foreign_key: true
      t.string :email, null: false
      t.references :invited_by, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :contest_invitations, [ :contest_instance_id, :email ], unique: true,
              name: 'index_contest_invitations_on_instance_and_email'
  end
end
