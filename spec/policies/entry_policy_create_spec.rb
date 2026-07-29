# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EntryPolicy do
  describe '#create?' do
    subject { described_class.new(user, entry) }

    let(:class_level) { create(:class_level) }
    let(:user) { profile.user }
    let(:profile) { create(:profile, class_level: class_level) }
    let(:entry) { build(:entry, profile: profile, contest_instance: contest_instance) }

    before do
      Current.redeemed_contest_instances = {}
    end

    after { Current.reset }

    context 'for a public contest' do
      let(:contest_instance) do
        create(:contest_instance).tap do |ci|
          ci.class_levels = [ class_level ]
          ci.save!
        end
      end

      it { is_expected.to permit_action(:create) }

      context 'when class level does not match' do
        let(:contest_instance) { create(:contest_instance) }

        it { is_expected.to forbid_action(:create) }
      end
    end

    context 'for a private capability_url contest' do
      let(:container) { create(:container, :private) }
      let(:description) { create(:contest_description, :active, container: container) }
      let(:contest_instance) do
        create(:contest_instance, contest_description: description).tap do |ci|
          ci.class_levels = [ class_level ]
          ci.save!
        end
      end

      it 'forbids create without a redeemed token' do
        expect(subject).to forbid_action(:create)
      end

      it 'permits create with a redeemed matching token' do
        Current.redeemed_contest_instances = {
          contest_instance.id.to_s => contest_instance.access_token
        }
        expect(subject).to permit_action(:create)
      end

      it 'forbids create after token regeneration (stale session token)' do
        old_token = contest_instance.access_token
        Current.redeemed_contest_instances = { contest_instance.id.to_s => old_token }
        contest_instance.regenerate_access_token

        expect(subject).to forbid_action(:create)
      end
    end

    context 'for a private invite_list contest' do
      let(:container) { create(:container, :private) }
      let(:description) { create(:contest_description, :active, container: container) }
      let(:contest_instance) do
        create(:contest_instance, :invite_list, contest_description: description).tap do |ci|
          ci.class_levels = [ class_level ]
          ci.save!
        end
      end

      before do
        Current.redeemed_contest_instances = {
          contest_instance.id.to_s => contest_instance.access_token
        }
      end

      it 'forbids create when the user is not invited' do
        expect(subject).to forbid_action(:create)
      end

      it 'permits create when the user is invited' do
        create(:contest_invitation, contest_instance: contest_instance, email: user.email)
        expect(subject).to permit_action(:create)
      end
    end
  end
end
