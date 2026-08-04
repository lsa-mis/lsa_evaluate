# frozen_string_literal: true

class AddAccessFieldsToContestInstances < ActiveRecord::Migration[8.1]
  def up
    add_column :contest_instances, :access_token, :string
    add_column :contest_instances, :access_mode, :string, null: false, default: 'capability_url'
    add_index :contest_instances, :access_token, unique: true

    # Backfill unguessable tokens for existing instances
    say_with_time 'Backfilling contest instance access tokens' do
      ContestInstance.reset_column_information
      ContestInstance.unscoped.find_each do |contest_instance|
        contest_instance.update_columns(access_token: SecureRandom.base58(24))
      end
    end

    change_column_null :contest_instances, :access_token, false
  end

  def down
    remove_index :contest_instances, :access_token
    remove_column :contest_instances, :access_token
    remove_column :contest_instances, :access_mode
  end
end
