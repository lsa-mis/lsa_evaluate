# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ContestInstance, type: :model do
  describe 'access token' do
    it 'generates an access_token on create' do
      contest_instance = create(:contest_instance)
      expect(contest_instance.access_token).to be_present
      expect(contest_instance.access_token.length).to be >= 24
    end

    it 'defaults access_mode to capability_url' do
      contest_instance = create(:contest_instance)
      expect(contest_instance).to be_capability_url
    end
  end

  describe '#private_visibility?' do
    it 'is true when the container is Private' do
      container = create(:container, :private)
      description = create(:contest_description, :active, container: container)
      contest_instance = create(:contest_instance, contest_description: description)

      expect(contest_instance).to be_private_visibility
      expect(contest_instance).not_to be_public_visibility
    end

    it 'is false when the container is Public' do
      contest_instance = create(:contest_instance)
      expect(contest_instance).to be_public_visibility
    end
  end

  describe '#available_for_profile?' do
    let(:class_level) { create(:class_level) }
    let(:contest_instance) do
      create(:contest_instance).tap do |ci|
        ci.class_levels = [ class_level ]
        ci.save!
      end
    end
    let(:profile) { create(:profile, class_level: class_level) }

    it 'returns true when class level matches and under entry cap' do
      expect(contest_instance.available_for_profile?(profile)).to be true
    end

    it 'returns false when class level does not match' do
      other_profile = create(:profile, class_level: create(:class_level))
      expect(contest_instance.available_for_profile?(other_profile)).to be false
    end
  end

  describe '#access_granted_for?' do
    let(:user) { create(:user) }
    let(:container) { create(:container, :private) }
    let(:description) { create(:contest_description, :active, container: container) }
    let(:contest_instance) { create(:contest_instance, contest_description: description) }

    it 'allows public contests without a token' do
      public_instance = create(:contest_instance)
      expect(public_instance.access_granted_for?(user)).to be true
    end

    it 'denies private contests without a matching redeemed token' do
      expect(contest_instance.access_granted_for?(user, redeemed_token: nil)).to be false
      expect(contest_instance.access_granted_for?(user, redeemed_token: 'wrong')).to be false
    end

    it 'allows private capability_url contests with a matching token' do
      expect(
        contest_instance.access_granted_for?(user, redeemed_token: contest_instance.access_token)
      ).to be true
    end

    context 'with invite_list mode' do
      let(:contest_instance) do
        create(:contest_instance, :invite_list, contest_description: description)
      end

      it 'denies when the user is not on the invite list' do
        expect(
          contest_instance.access_granted_for?(user, redeemed_token: contest_instance.access_token)
        ).to be false
      end

      it 'allows when the user is on the invite list' do
        create(:contest_invitation, contest_instance: contest_instance, email: user.email)
        expect(
          contest_instance.access_granted_for?(user, redeemed_token: contest_instance.access_token)
        ).to be true
      end
    end
  end
end
