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
#  umid                          :string(255)
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  campus_id                     :bigint
#  class_level_id                :bigint
#  school_id                     :bigint
#  user_id                       :bigint           not null
#
# Indexes
#
#  campus_id_idx                     (campus_id)
#  class_level_id_idx                (class_level_id)
#  id_unq_idx                        (id) UNIQUE
#  index_profiles_on_campus_id       (campus_id)
#  index_profiles_on_class_level_id  (class_level_id)
#  index_profiles_on_school_id       (school_id)
#  index_profiles_on_umid            (umid) UNIQUE
#  index_profiles_on_user_id         (user_id)
#  school_id_idx                     (school_id)
#  user_id_idx                       (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (campus_id => campuses.id)
#  fk_rails_...  (class_level_id => class_levels.id)
#  fk_rails_...  (school_id => schools.id)
#  fk_rails_...  (user_id => users.id)
#
require 'rails_helper'

RSpec.describe Profile do
  let(:user) { create(:user) }

  let(:associated_records) do
    {
      class_level: create(:class_level),
      school: create(:school),
      campus: create(:campus)
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

  describe 'UMID validations' do
    let(:associated_records) do
      {
        class_level: create(:class_level),
        school: create(:school),
        campus: create(:campus)
      }
    end

    let(:profile) do
      build(:profile, **associated_records)
    end

    context 'format validation' do
      it 'is valid with an 8-digit number' do
        profile.umid = '12345678'
        expect(profile).to be_valid
      end

      it 'is valid with an 8-digit number starting with 0' do
        profile.umid = '00345678'
        expect(profile).to be_valid
      end

      it 'is invalid with letters' do
        profile.umid = '1234567a'
        expect(profile).not_to be_valid
        expect(profile.errors[:umid]).to include('must be exactly 8 digits')
      end

      it 'is invalid with special characters' do
        profile.umid = '1234567!'
        expect(profile).not_to be_valid
        expect(profile.errors[:umid]).to include('must be exactly 8 digits')
      end

      it 'is invalid with spaces' do
        profile.umid = '1234 567'
        expect(profile).not_to be_valid
        expect(profile.errors[:umid]).to include('must be exactly 8 digits')
      end
    end

    context 'length validation' do
      it 'is invalid with less than 8 digits' do
        profile.umid = '1234567'
        expect(profile).not_to be_valid
        expect(profile.errors[:umid]).to include('is the wrong length (should be 8 characters)')
      end

      it 'is invalid with more than 8 digits' do
        profile.umid = '123456789'
        expect(profile).not_to be_valid
        expect(profile.errors[:umid]).to include('is the wrong length (should be 8 characters)')
      end
    end

    context 'uniqueness validation' do
      it 'is invalid with a duplicate UMID' do
        create(:profile, umid: '87654321', **associated_records)
        profile.umid = '87654321'
        expect(profile).not_to be_valid
        expect(profile.errors[:umid]).to include('has already been taken')
      end
    end

    context 'presence validation' do
      it 'is invalid when nil' do
        profile.umid = nil
        expect(profile).not_to be_valid
        expect(profile.errors[:umid]).to include("can't be blank")
      end

      it 'is invalid when empty string' do
        profile.umid = ''
        expect(profile).not_to be_valid
        expect(profile.errors[:umid]).to include("can't be blank")
      end

      it 'is invalid when only spaces' do
        profile.umid = '        '
        expect(profile).not_to be_valid
        expect(profile.errors[:umid]).to include('must be exactly 8 digits')
      end
    end
  end
end
