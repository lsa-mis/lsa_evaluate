# == Schema Information
#
# Table name: visibilities
#
#  id          :bigint           not null, primary key
#  description :text(65535)
#  kind        :string(255)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
FactoryBot.define do
  factory :visibility do
    kind { "MyString" }
    description { "MyText" }
  end
end
