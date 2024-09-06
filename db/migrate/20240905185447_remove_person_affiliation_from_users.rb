class RemovePersonAffiliationFromUsers < ActiveRecord::Migration[7.2]
  def change
    remove_column :users, :person_affiliation, :string
  end
end
