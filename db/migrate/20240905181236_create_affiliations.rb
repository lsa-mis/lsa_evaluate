class CreateAffiliations < ActiveRecord::Migration[7.2]
  def change
    create_table :affiliations do |t|
      t.string :name
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
