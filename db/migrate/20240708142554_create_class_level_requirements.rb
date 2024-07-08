class CreateClassLevelRequirements < ActiveRecord::Migration[7.1]
  def change
    create_table :class_level_requirements do |t|
      t.references :contest_instance, null: false, foreign_key: true
      t.references :class_level, null: false, foreign_key: true

      t.timestamps
    end

    add_index :class_level_requirements, %i[contest_instance_id class_level_id], unique: true,
                                                                                 name: 'index_clr_on_ci_and_cl'
  end
end
