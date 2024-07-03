class CreateStatuses < ActiveRecord::Migration[7.1]
  # Creates a new table called "statuses" with the specified columns.
  #
  # @return [void]
  def change
    create_table :statuses do |t|
      t.string :kind, null: false
      t.text :description

      t.timestamps
    end
  end
end
