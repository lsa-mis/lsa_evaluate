# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AwardPolicy do
  subject { described_class.new(user, award) }

  let(:container) { create(:container) }
  let(:award) { create(:award, container: container) }

  shared_examples 'catalog manage permissions' do |action|
    context 'for a visitor' do
      let(:user) { nil }

      it { is_expected.not_to permit_action(action) }
    end

    context 'for a Collection Administrator of the award collection' do
      let(:user) { create(:user) }
      let(:admin_role) { create(:role, kind: 'Collection Administrator') }

      before do
        create(:assignment, user: user, container: container, role: admin_role)
      end

      it { is_expected.to permit_action(action) }
    end

    context 'for a Collection Manager of the award collection' do
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

    context 'for a judge with only a Judge assignment on the collection' do
      let(:user) { create(:user, :with_judge_role) }
      let(:judge_role) { create(:role, kind: 'Judge') }

      before do
        create(:assignment, user: user, container: container, role: judge_role)
      end

      it { is_expected.not_to permit_action(action) }
    end

    context 'for an unrelated user' do
      let(:user) { create(:user) }

      it { is_expected.not_to permit_action(action) }
    end
  end

  describe '#index?' do
    include_examples 'catalog manage permissions', :index
  end

  describe '#create?' do
    include_examples 'catalog manage permissions', :create
  end

  describe '#update?' do
    include_examples 'catalog manage permissions', :update
  end

  describe '#destroy?' do
    include_examples 'catalog manage permissions', :destroy
  end
end
