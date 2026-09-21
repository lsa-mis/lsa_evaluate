# == Schema Information
#
# Table name: entries
#
#  id                            :bigint           not null, primary key
#  accepted_financial_aid_notice :boolean          default(FALSE), not null
#  campus_employee               :boolean          default(FALSE), not null
#  deleted                       :boolean          default(FALSE), not null
#  disqualified                  :boolean          default(FALSE), not null
#  financial_aid_description     :text(65535)
#  pen_name                      :string(255)
#  receiving_financial_aid       :boolean          default(FALSE), not null
#  title                         :string(255)      not null
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  category_id                   :bigint           not null
#  contest_instance_id           :bigint           not null
#  profile_id                    :bigint           not null
#
# Indexes
#
#  category_id_idx                       (category_id)
#  contest_instance_id_idx               (contest_instance_id)
#  id_unq_idx                            (id) UNIQUE
#  index_entries_on_category_id          (category_id)
#  index_entries_on_contest_instance_id  (contest_instance_id)
#  index_entries_on_profile_id           (profile_id)
#  profile_id_idx                        (profile_id)
#
# Foreign Keys
#
#  fk_rails_...  (category_id => categories.id)
#  fk_rails_...  (contest_instance_id => contest_instances.id)
#  fk_rails_...  (profile_id => profiles.id)
#
FactoryBot.define do
  factory :entry do
    title { 'Sample Entry Title' }
    disqualified { false }
    deleted { false }
    pen_name { 'Sample Pen Name' }
    receiving_financial_aid { false }
    accepted_financial_aid_notice { false }
    financial_aid_description { 'Sample Financial Aid Description' }
    campus_employee { false }
    contest_instance
    profile

    after(:build) do |entry|
      if entry.contest_instance.present?
        container = entry.contest_instance.contest_description.container

        if entry.category.nil?
          entry.category = entry.contest_instance.categories.first ||
                           build(:category, :general, container: container)
        elsif entry.category.container_id != container.id
          entry.category = container.categories.find_by(kind: entry.category.kind) ||
                           build(
                             :category,
                             kind: entry.category.kind,
                             description: entry.category.description.presence || "Description for #{entry.category.kind}",
                             container: container
                           )
        end

        unless entry.contest_instance.categories.include?(entry.category)
          entry.contest_instance.categories << entry.category
        end
      end

      entry.entry_file.attach(
        io: Rails.root.join('spec/support/files/sample_test.pdf').open,
        filename: 'sample_test.pdf',
        content_type: 'application/pdf'
      )
    end
  end
end
