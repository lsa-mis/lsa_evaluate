class AddContactEmailToContainers < ActiveRecord::Migration[7.2]
  def change
    add_column :containers, :contact_email, :string
  end
end
