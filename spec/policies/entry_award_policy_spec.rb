# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EntryAwardPolicy do
  subject { described_class.new(user, entry_award) }

  let(:container) { create(:container) }
  let(:contest_description) { create(:contest_description, :active, container: container) }
  let(:contest_instance) { create(:contest_instance, contest_description: contest_description) }
  let(:entry) { create(:entry, contest_instance: contest_instance) }
  let(:award) { create(:award, container: container) }
  let(:entry_award) { build(:entry_award, entry: entry, award: award) }

  shared_examples 'award assignment permissions' do |action|
    context 'for a visitor' do
      let(:user) { nil }

      it { is_expected.not_to permit_action(action) }
    end

    context 'for a Collection Administrator of the entry collection' do
      let(:user) { create(:user) }
      let(:admin_role) { create(:role, kind: 'Collection Administrator') }

      before do
        create(:assignment, user: user, container: container, role: admin_role)
      end

      it { is_expected.to permit_action(action) }
    end

    context 'for a Collection Manager of the entry collection' do
      let(:user) { create(:user) }
      let(:manager_role) { create(:role, kind: 'Collection Manager') }

      before do
        create(:assignment, user: user, container: container, role: manager_role)
      end

      it { is_expected.to permit_action(action) }
    end

    context 'for Axis Mundi' do
      let(:user) { create(:user, :axis_mundi) }

      it { is_expected.to permit_action(action) }
    end

    context 'for a Collection Administrator of a different collection' do
      let(:user) { create(:user) }
      let(:admin_role) { create(:role, kind: 'Collection Administrator') }
      let(:other_container) { create(:container) }

      before do
        create(:assignment, user: user, container: other_container, role: admin_role)
      end

      it { is_expected.not_to permit_action(action) }
    end

    context 'for a judge assigned to the contest instance' do
      let(:user) { create(:user, :with_judge_role) }

      before do
        create(:judging_assignment, user: user, contest_instance: contest_instance)
      end

      it { is_expected.not_to permit_action(action) }
    end

    context 'for an unrelated user' do
      let(:user) { create(:user) }

      it { is_expected.not_to permit_action(action) }
    end
  end

  describe '#create?' do
    include_examples 'award assignment permissions', :create
  end

  describe '#update?' do
    include_examples 'award assignment permissions', :update
  end

  describe '#destroy?' do
    include_examples 'award assignment permissions', :destroy
  end
end
