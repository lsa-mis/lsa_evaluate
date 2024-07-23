# == Schema Information
#
# Table name: profiles
#
#  id                            :bigint           not null, primary key
#  accepted_financial_aid_notice :boolean          default(FALSE), not null
#  degree                        :string(255)      not null
#  financial_aid_description     :text(65535)
#  first_name                    :string(255)      default(""), not null
#  grad_date                     :date             not null
#  hometown_publication          :string(255)
#  last_name                     :string(255)      default(""), not null
#  major                         :string(255)
#  pen_name                      :string(255)
#  receiving_financial_aid       :boolean          default(FALSE), not null
#  umid                          :integer          not null
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  campus_address_id             :bigint
#  campus_id                     :bigint
#  class_level_id                :bigint
#  department_id                 :bigint
#  home_address_id               :bigint
#  school_id                     :bigint
#  user_id                       :bigint           not null
#
# Indexes
#
#  campus_id_idx                        (campus_id)
#  class_level_id_idx                   (class_level_id)
#  id_unq_idx                           (id) UNIQUE
#  index_profiles_on_campus_address_id  (campus_address_id)
#  index_profiles_on_campus_id          (campus_id)
#  index_profiles_on_class_level_id     (class_level_id)
#  index_profiles_on_department_id      (department_id)
#  index_profiles_on_home_address_id    (home_address_id)
#  index_profiles_on_school_id          (school_id)
#  index_profiles_on_user_id            (user_id)
#  school_id_idx                        (school_id)
#  user_id_idx                          (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (campus_address_id => addresses.id)
#  fk_rails_...  (campus_id => campuses.id)
#  fk_rails_...  (class_level_id => class_levels.id)
#  fk_rails_...  (department_id => departments.id)
#  fk_rails_...  (home_address_id => addresses.id)
#  fk_rails_...  (school_id => schools.id)
#  fk_rails_...  (user_id => users.id)
#
require 'rails_helper'

RSpec.describe Profile do # rubocop:disable RSpec/MultipleMemoizedHelpers
  let(:user) { create(:user) }
  let(:class_level) { create(:class_level) }
  let(:school) { create(:school) }
  let(:campus) { create(:campus) }
  let(:department) { create(:department) }
  # let(:address) { create(:address) }

  let(:profile) do
    described_class.new(
      user:,
      first_name: Faker::Name.first_name,
      last_name: Faker::Name.last_name,
      umid: Faker::Number.number(digits: 8),
      class_level:,
      school:,
      campus:,
      major: Faker::Educator.subject,
      department:,
      grad_date: Faker::Date.forward(days: 365),
      degree: Faker::Educator.degree,
      receiving_financial_aid: Faker::Boolean.boolean,
      accepted_financial_aid_notice: Faker::Boolean.boolean,
      financial_aid_description: Faker::Lorem.paragraph,
      hometown_publication: Faker::Address.city,
      pen_name: Faker::Book.author
    )
  end

  describe 'validations' do
    it 'is valid with valid attributes' do
      expect(profile).to be_valid
    end

    it 'is not valid without a first_name' do
      profile.first_name = nil
      expect(profile).not_to be_valid
    end

    it 'is not valid without a last_name' do
      profile.last_name = nil
      expect(profile).not_to be_valid
    end

    it 'is not valid without a grad_date' do
      profile.grad_date = nil
      expect(profile).not_to be_valid
    end

    it 'is not valid without a degree' do
      profile.degree = nil
      expect(profile).not_to be_valid
    end

    it 'is not valid without receiving_financial_aid' do
      profile.receiving_financial_aid = nil
      expect(profile).not_to be_valid
    end

    it 'is not valid without accepted_financial_aid_notice' do
      profile.accepted_financial_aid_notice = nil
      expect(profile).not_to be_valid
    end
  end

  describe 'associations' do
    it 'belongs to user' do
      expect(profile.user).to eq(user)
    end

    it 'belongs to class_level' do
      expect(profile.class_level).to eq(class_level)
    end

    it 'belongs to school' do
      expect(profile.school).to eq(school)
    end

    it 'belongs to campus' do
      expect(profile.campus).to eq(campus)
    end

    it 'belongs to department' do
      expect(profile.department).to eq(department)
    end

    # it 'belongs to address' do
    #   expect(profile.address).to eq(address)
    # end
  end
end
