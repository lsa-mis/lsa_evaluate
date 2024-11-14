class CreateContestDescriptions < ActiveRecord::Migration[7.1]
  def change
    create_table :contest_descriptions do |t|
      t.references :container, null: false, foreign_key: true
      t.string :name, null: false
      t.string :short_name
      t.text :eligibility_rules
      t.text :notes
      t.string :created_by, null: false

      t.timestamps
    end
  end
end
