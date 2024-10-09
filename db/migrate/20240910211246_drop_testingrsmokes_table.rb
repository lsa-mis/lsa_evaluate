class DropTestingrsmokesTable < ActiveRecord::Migration[7.2]
  def change
    drop_table :testingrsmokes do |t|
      t.string :name, null: false
      t.timestamps
    end
  end
end
