class DropStatusesTable < ActiveRecord::Migration[7.2]
  def change
    drop_table :statuses do |t|
      t.string :kind, null: false
      t.text :description
      t.timestamps
    end
  end
end
