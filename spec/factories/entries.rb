# == Schema Information
#
# Table name: entries
#
#  id                  :bigint           not null, primary key
#  title               :string(255)      not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  category_id         :bigint           not null
#  contest_instance_id :bigint           not null
#  profile_id          :bigint           not null
#  status_id           :bigint           not null
#
# Indexes
#
#  category_id_idx                       (category_id)
#  contest_instance_id_idx               (contest_instance_id)
#  id_unq_idx                            (id) UNIQUE
#  index_entries_on_category_id          (category_id)
#  index_entries_on_contest_instance_id  (contest_instance_id)
#  index_entries_on_profile_id           (profile_id)
#  index_entries_on_status_id            (status_id)
#  profile_id_idx                        (profile_id)
#  status_id_idx                         (status_id)
#
# Foreign Keys
#
#  fk_rails_...  (category_id => categories.id)
#  fk_rails_...  (contest_instance_id => contest_instances.id)
#  fk_rails_...  (profile_id => profiles.id)
#  fk_rails_...  (status_id => statuses.id)
#
# spec/factories/entries.rb
FactoryBot.define do
  factory :entry do
    title { "Sample Entry Title" }
    status
    contest_instance
    profile
    category

    # If you want to add an attached file, you can use this
    after(:build) do |entry|
      entry.entry_file.attach(
        io: File.open(Rails.root.join("spec/support/files/sample_test.pdf")),
        filename: 'sample_test.pdf',
        content_type: 'application/pdf'
      )
    end
  end
end
