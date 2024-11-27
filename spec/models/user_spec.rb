# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id                     :bigint           not null, primary key
#  current_sign_in_at     :datetime
#  current_sign_in_ip     :string(255)
#  display_name           :string(255)
#  email                  :string(255)      default(""), not null
#  encrypted_password     :string(255)      default(""), not null
#  failed_attempts        :integer          default(0), not null
#  first_name             :string(255)      default(""), not null
#  last_name              :string(255)      default(""), not null
#  last_sign_in_at        :datetime
#  last_sign_in_ip        :string(255)
#  locked_at              :datetime
#  principal_name         :string(255)
#  provider               :string(255)
#  remember_created_at    :datetime
#  reset_password_sent_at :datetime
#  reset_password_token   :string(255)
#  sign_in_count          :integer          default(0), not null
#  uid                    :string(255)
#  uniqname               :string(255)
#  unlock_token           :string(255)
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#  index_users_on_unlock_token          (unlock_token) UNIQUE
#
require 'rails_helper'

RSpec.describe User do
  subject { build(:user) } # Assuming you have a User factory set up

  describe 'validations' do
    it 'validates presence of email' do
      user = build(:user, email: nil)
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include("can't be blank")
    end

    it 'validates presence of encrypted_password' do
      user = build(:user, encrypted_password: nil)
      expect(user).not_to be_valid
      expect(user.errors[:encrypted_password]).to include("can't be blank")
    end

    it 'validates uniqueness of email' do
      create(:user, email: 'unique@example.com')
      user = build(:user, email: 'unique@example.com')
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include('has already been taken')
    end
  end

  describe 'associations' do
    # Add association tests here if there are any, for example:
    # it { should have_many(:posts) }
  end

  describe 'devise modules' do
    it 'includes database_authenticatable module' do
      expect(described_class.ancestors).to include(Devise::Models::DatabaseAuthenticatable)
    end

    it 'includes registerable module' do
      expect(described_class.ancestors).to include(Devise::Models::Registerable)
    end

    it 'includes recoverable module' do
      expect(described_class.ancestors).to include(Devise::Models::Recoverable)
    end

    it 'includes rememberable module' do
      expect(described_class.ancestors).to include(Devise::Models::Rememberable)
    end

    it 'includes validatable module' do
      expect(described_class.ancestors).to include(Devise::Models::Validatable)
    end

    it 'includes trackable module' do
      expect(described_class.ancestors).to include(Devise::Models::Trackable)
    end

    it 'includes lockable module' do
      expect(described_class.ancestors).to include(Devise::Models::Lockable)
    end

    it 'includes timeoutable module' do
      expect(described_class.ancestors).to include(Devise::Models::Timeoutable)
    end

    it 'includes omniauthable module' do
      expect(described_class.ancestors).to include(Devise::Models::Omniauthable)
    end
  end

  describe 'instance methods' do
    describe '#display_initials_or_uid' do
      context 'when display_name is present' do
        it 'returns initials of display_name' do
          user = build(:user, display_name: 'John Doe')
          expect(user.display_initials_or_uid).to eq('JD')
        end
      end

      context 'when display_name is not present' do
        it 'returns the first leter of the uid' do
          user = build(:user, uid: 'user', display_name: nil)
          expect(user.display_initials_or_uid).to eq('U')
        end
      end
    end
  end
end
