# frozen_string_literal: true

class AddLegalNamesAndRelaxProfileRequirements < ActiveRecord::Migration[8.1]
  def up
    add_column :profiles, :legal_first_name, :string
    add_column :profiles, :legal_last_name, :string

    execute <<~SQL.squish
      UPDATE profiles
      SET legal_first_name = preferred_first_name,
          legal_last_name = preferred_last_name
      WHERE (legal_first_name IS NULL OR legal_first_name = '')
         OR (legal_last_name IS NULL OR legal_last_name = '')
    SQL

    change_column_null :profiles, :legal_first_name, false
    change_column_null :profiles, :legal_last_name, false
    change_column_default :profiles, :preferred_first_name, from: '', to: nil
    change_column_default :profiles, :preferred_last_name, from: '', to: nil
    change_column_null :profiles, :preferred_first_name, true
    change_column_null :profiles, :preferred_last_name, true
    change_column_null :profiles, :degree, true
    change_column_null :profiles, :grad_date, true
  end

  def down
    change_column_null :profiles, :degree, false
    change_column_null :profiles, :grad_date, false
    change_column_null :profiles, :preferred_first_name, false
    change_column_null :profiles, :preferred_last_name, false
    change_column_default :profiles, :preferred_first_name, from: nil, to: ''
    change_column_default :profiles, :preferred_last_name, from: nil, to: ''
    remove_column :profiles, :legal_first_name
    remove_column :profiles, :legal_last_name
  end
end
