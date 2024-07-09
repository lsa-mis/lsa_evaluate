class CreateCampuses < ActiveRecord::Migration[7.1]
  def change
    create_table :campuses do |t|
      t.string :campus_descr, null: false
      t.integer :campus_cd, null: false

      t.timestamps
    end

    add_index :campuses, :id, unique: true, name: :id_unq_idx
    add_index :campuses, :campus_descr, name: :campus_descr_idx
    add_index :campuses, :campus_descr, unique: true, name: :campus_descr_unq_idx
    add_index :campuses, :campus_cd, unique: true, name: :campus_cd_unq_idx
  end
end
