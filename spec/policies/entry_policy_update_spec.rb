# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EntryPolicy do
  describe '#update?' do
    subject { described_class.new(user, entry) }

    let(:class_level) { create(:class_level) }
    let(:profile) { create(:profile, class_level: class_level) }
    let(:contest_instance) do
      create(:contest_instance).tap do |ci|
        ci.class_levels = [ class_level ]
        ci.save!
      end
    end
    let(:entry) { create(:entry, profile: profile, contest_instance: contest_instance) }

    context 'for the entry owner while the contest is open' do
      let(:user) { profile.user }

      it { is_expected.to permit_action(:update) }
      it { is_expected.to permit_action(:edit) }
    end

    context 'for the entry owner after the contest closes' do
      let(:user) { profile.user }
      let(:contest_instance) do
        create(:contest_instance, date_open: 2.days.ago, date_closed: 1.day.ago).tap do |ci|
          ci.class_levels = [ class_level ]
          ci.save!
        end
      end

      it { is_expected.to forbid_action(:update) }
    end

    context 'for the entry owner when the entry is soft-deleted' do
      let(:user) { profile.user }
      let(:entry) { create(:entry, profile: profile, contest_instance: contest_instance, deleted: true) }

      it { is_expected.to forbid_action(:update) }
    end

    context 'for an unrelated user' do
      let(:user) { create(:user) }

      it { is_expected.to forbid_action(:update) }
    end

    context 'for axis mundi after the contest closes' do
      let(:user) { create(:user, :axis_mundi) }
      let(:contest_instance) do
        create(:contest_instance, date_open: 2.days.ago, date_closed: 1.day.ago).tap do |ci|
          ci.class_levels = [ class_level ]
          ci.save!
        end
      end

      it { is_expected.to permit_action(:update) }
    end
  end
end
