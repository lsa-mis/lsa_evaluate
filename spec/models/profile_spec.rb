# frozen_string_literal: true

# == Schema Information
#
# Table name: profiles
#
#  id                            :bigint           not null, primary key
#  accepted_financial_aid_notice :boolean          default(FALSE), not null
#  campus_employee               :boolean          default(FALSE), not null
#  degree                        :string(255)      not null
#  department                    :string(255)
#  financial_aid_description     :text(65535)
#  grad_date                     :date             not null
#  hometown_publication          :string(255)
#  major                         :string(255)
#  pen_name                      :string(255)
#  preferred_first_name          :string(255)      default(""), not null
#  preferred_last_name           :string(255)      default(""), not null
#  receiving_financial_aid       :boolean          default(FALSE), not null
#  umid                          :integer          not null
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  campus_address_id             :bigint
#  campus_id                     :bigint
#  class_level_id                :bigint
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
#  index_profiles_on_home_address_id    (home_address_id)
#  index_profiles_on_school_id          (school_id)
#  index_profiles_on_umid               (umid) UNIQUE
#  index_profiles_on_user_id            (user_id)
#  school_id_idx                        (school_id)
#  user_id_idx                          (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (campus_address_id => addresses.id)
#  fk_rails_...  (campus_id => campuses.id)
#  fk_rails_...  (class_level_id => class_levels.id)
#  fk_rails_...  (home_address_id => addresses.id)
#  fk_rails_...  (school_id => schools.id)
#  fk_rails_...  (user_id => users.id)
#
require 'rails_helper'

RSpec.describe Profile do
  let(:user) { create(:user) }

  let(:addresses) { create_list(:address, 2) }
  let(:associated_records) do
    {
      class_level: create(:class_level),
      school: create(:school),
      campus: create(:campus),
      home_address: addresses.first,
      campus_address: addresses.second
    }
  end

  let(:profile) do
    described_class.new(
      user:,
      preferred_first_name: Faker::Name.first_name,
      preferred_last_name: Faker::Name.last_name,
      umid: Faker::Number.number(digits: 8),
      grad_date: Faker::Date.forward(days: 365),
      degree: Faker::Educator.degree,
      hometown_publication: Faker::Address.city,
      pen_name: Faker::Book.author,
      **associated_records
    )
  end

  describe 'validations' do
    it 'is valid with valid attributes' do
      expect(profile).to be_valid
    end

    it 'is not valid without a preferred_first_name' do
      profile.preferred_first_name = nil
      expect(profile).not_to be_valid
    end

    it 'is not valid with a preferred_first_name longer than 255 characters' do
      profile.preferred_first_name = 'a' * 256
      expect(profile).not_to be_valid
    end

    it 'is not valid without a preferred_last_name' do
      profile.preferred_last_name = nil
      expect(profile).not_to be_valid
    end

    it 'is not valid with a preferred_last_name longer than 255 characters' do
      profile.preferred_last_name = 'a' * 256
      expect(profile).not_to be_valid
    end

    it 'is not valid with an invalid umid format' do
      profile.umid = 'invalid_umid'
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

    it 'is not valid without umid' do
      profile.umid = nil
      expect(profile).not_to be_valid
    end

    it 'is not with a umid less than 8 digits' do
      profile.umid = Faker::Number.number(digits: 7)
      expect(profile).not_to be_valid
    end

    it 'is not with a umid greater than 8 digits' do
      profile.umid = Faker::Number.number(digits: 9)
      expect(profile).not_to be_valid
    end

    it 'is not valid if umid is not unique' do
      profile.save
      duplicate_profile = profile.dup
      expect(duplicate_profile).not_to be_valid
    end
  end

  describe 'associations' do
    it 'belongs to user' do
      expect(profile.user).to eq(user)
    end

    it 'belongs to class_level' do
      expect(profile.class_level).to eq(associated_records[:class_level])
    end

    it 'belongs to school' do
      expect(profile.school).to  eq(associated_records[:school])
    end

    it 'belongs to campus' do
      expect(profile.campus).to  eq(associated_records[:campus])
    end

    it 'belongs to home_address' do
      expect(profile.home_address).to eq(associated_records[:home_address])
    end

    it 'belongs to campus_address' do
      expect(profile.campus_address).to eq(associated_records[:campus_address])
    end

    it 'accepts nested attributes for home_address' do
      profile_attributes = attributes_for(:profile, home_address_attributes: attributes_for(:address))
      profile = described_class.new(profile_attributes)
      expect(profile.home_address).to be_present
    end

    it 'accepts nested attributes for campus_address' do
      profile_attributes = attributes_for(:profile, campus_address_attributes: attributes_for(:address))
      profile = described_class.new(profile_attributes)
      expect(profile.campus_address).to be_present
    end
  end

  describe 'callbacks' do
    describe 'before_save normalize_names' do
      it 'normalizes the preferred_first_name before saving' do
        profile.preferred_first_name = '  John  '
        profile.save
        expect(profile.preferred_first_name).to eq('John')
      end

      it 'normalizes the preferred_last_name before saving' do
        profile.preferred_last_name = '  Popper  '
        profile.save
        expect(profile.preferred_last_name).to eq('Popper')
      end
    end
  end
end
