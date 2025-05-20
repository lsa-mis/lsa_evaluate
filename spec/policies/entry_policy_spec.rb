require 'rails_helper'

RSpec.describe EntryPolicy do
  subject { described_class.new(user, entry) }

  let(:profile) { create(:profile) }
  let(:contest_instance) { create(:contest_instance) }
  let(:entry) { create(:entry, profile: profile, contest_instance: contest_instance) }

  context "for a visitor" do
    let(:user) { nil }
    it { is_expected.to forbid_action(:show) }
  end

  context "for entry owner" do
    let(:user) { profile.user }
    it { is_expected.to permit_action(:show) }
  end

  context "for an admin in the same container" do
    let(:user) { create(:user) }
    let(:container) { contest_instance.contest_description.container }
    let(:admin_role) { create(:role, kind: 'Collection Administrator') }

    before do
      create(:assignment, user: user, container: container, role: admin_role)
    end

    it { is_expected.to permit_action(:show) }
  end

  context "for a manager in the same container" do
    let(:user) { create(:user) }
    let(:container) { contest_instance.contest_description.container }
    let(:manager_role) { create(:role, kind: 'Collection Manager') }

    before do
      create(:assignment, user: user, container: container, role: manager_role)
    end

    it { is_expected.to permit_action(:show) }
  end

  context "for a judge assigned to the contest instance" do
    let(:user) { create(:user, :with_judge_role) }

    before do
      create(:judging_assignment, user: user, contest_instance: contest_instance)
    end

    it { is_expected.to permit_action(:show) }
  end

  context "for an unrelated user" do
    let(:user) { create(:user) }
    it { is_expected.to forbid_action(:show) }
  end

  context "for axis mundi" do
    let(:user) { create(:user, :axis_mundi) }
    it { is_expected.to permit_action(:show) }
  end
end
