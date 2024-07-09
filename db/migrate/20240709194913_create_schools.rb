class CreateSchools < ActiveRecord::Migration[7.1]
  def change
    create_table :schools do |t|
      t.string :name

      t.timestamps
    end

    add_index :schools, :id, unique: true, name: :id_unq_idx
  end
end
