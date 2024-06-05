class CreateContainers < ActiveRecord::Migration[7.1]
  def change
    create_table :containers do |t|
      t.string :name
      t.text :description
      t.references :department, null: false, foreign_key: true
      t.references :visibility, null: false, foreign_key: true

      t.timestamps
    end
  end
end
