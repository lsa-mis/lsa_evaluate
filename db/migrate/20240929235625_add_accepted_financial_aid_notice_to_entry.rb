class AddAcceptedFinancialAidNoticeToEntry < ActiveRecord::Migration[7.2]
  def change
    add_column :entries, :accepted_financial_aid_notice, :boolean, default: false, null: false
    add_column :entries, :receiving_financial_aid, :boolean, default: false, null: false
    add_column :entries, :financial_aid_description, :text
  end
end
