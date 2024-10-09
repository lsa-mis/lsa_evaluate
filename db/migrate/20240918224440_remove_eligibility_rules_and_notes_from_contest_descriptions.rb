class RemoveEligibilityRulesAndNotesFromContestDescriptions < ActiveRecord::Migration[7.2]
  def change
    remove_column :contest_descriptions, :eligibility_rules, :text
    remove_column :contest_descriptions, :notes, :text
  end
end
