class CreateCategoryContestInstances < ActiveRecord::Migration[7.2]
  def change
    create_table :category_contest_instances do |t|
      t.references :category, null: false, foreign_key: true
      t.references :contest_instance, null: false, foreign_key: true

      t.timestamps
    end

    add_index :category_contest_instances, [ :category_id, :contest_instance_id ], unique: true, name: 'index_cat_ci_on_category_and_contest_instance'
  end
end
