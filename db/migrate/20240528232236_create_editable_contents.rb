class CreateEditableContents < ActiveRecord::Migration[7.1]
  def change
    create_table :editable_contents do |t|
      t.string :page, null: false
      t.string :section, null: false

      t.timestamps
    end

    add_index :editable_contents, %i[page section], unique: true
  end
end
