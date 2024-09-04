# == Schema Information
#
# Table name: category_contest_instances
#
#  id                  :bigint           not null, primary key
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  category_id         :bigint           not null
#  contest_instance_id :bigint           not null
#
# Indexes
#
#  index_cat_ci_on_category_and_contest_instance            (category_id,contest_instance_id) UNIQUE
#  index_category_contest_instances_on_category_id          (category_id)
#  index_category_contest_instances_on_contest_instance_id  (contest_instance_id)
#
# Foreign Keys
#
#  fk_rails_...  (category_id => categories.id)
#  fk_rails_...  (contest_instance_id => contest_instances.id)
#
# spec/factories/category_contest_instances.rb
FactoryBot.define do
  factory :category_contest_instance do
    category { Category.find_or_create_by(kind: 'Drama') }
    contest_instance
  end
end
