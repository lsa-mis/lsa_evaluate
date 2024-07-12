class AddHomeAndCampusAddressesToProfiles < ActiveRecord::Migration[7.1]
  def change
    add_reference :profiles, :home_address, foreign_key: { to_table: :addresses }
    add_reference :profiles, :campus_address, foreign_key: { to_table: :addresses }
  end
end
