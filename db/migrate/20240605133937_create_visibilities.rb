class CreateVisibilities < ActiveRecord::Migration[7.1]
  def change
    create_table :visibilities do |t|
      t.string :kind
      t.text :description

      t.timestamps
    end
  end
end
