# frozen_string_literal: true

# This migration adds the `uniqname` column to the `users` table.
# The `uniqname` column is used to store the unique identifier for each user.
# This migration is part of the database schema changes required for the LSA Evaluate application.
class AddUniqnameToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :uniqname, :string
    add_column :users, :provider, :string
    add_column :users, :uid, :string
    add_column :users, :principal_name, :string
    add_column :users, :display_name, :string
    add_column :users, :person_affiliation, :string
  end
end
