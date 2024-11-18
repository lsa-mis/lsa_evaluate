# == Schema Information
#
# Table name: entries
#
#  id                            :bigint           not null, primary key
#  title                         :string(255)      not null
#  contest_instance_id           :bigint           not null
#  profile_id                    :bigint           not null
#  category_id                   :bigint           not null
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  disqualified                  :boolean          default(FALSE), not null
#  deleted                       :boolean          default(FALSE), not null
#  pen_name                      :string(255)
#  campus_employee               :boolean          default(FALSE), not null
#  accepted_financial_aid_notice :boolean          default(FALSE), not null
#  receiving_financial_aid       :boolean          default(FALSE), not null
#  financial_aid_description     :text(65535)
#
FactoryBot.define do
  factory :entry do
    title { "Sample Entry Title" }
    disqualified { false }
    deleted { false }
    pen_name { "Sample Pen Name" }
    receiving_financial_aid { false }
    accepted_financial_aid_notice { false }
    financial_aid_description { "Sample Financial Aid Description" }
    campus_employee { false }
    contest_instance
    profile
    category { Category.find_by(kind: 'General') || association(:category, :general) }

    # If you want to add an attached file, you can use this
    after(:build) do |entry|
      entry.entry_file.attach(
        io: Rails.root.join("spec/support/files/sample_test.pdf").open,
        filename: 'sample_test.pdf',
        content_type: 'application/pdf'
      )
    end
  end
end
