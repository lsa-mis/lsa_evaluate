# == Schema Information
#
# Table name: editable_contents
#
#  id         :bigint           not null, primary key
#  page       :string(255)      not null
#  section    :string(255)      not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_editable_contents_on_page_and_section  (page,section) UNIQUE
#
FactoryBot.define do
  factory :editable_content do
    page { Faker::Lorem.word }
    section { Faker::Lorem.word }

    after(:build) do |editable_content|
      editable_content.content = ActionText::RichText.new(body: Faker::Lorem.paragraph)
    end
  end
end
