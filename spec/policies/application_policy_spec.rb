# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationPolicy, type: :policy do
  let(:record) { Object.new }

  describe 'default action permissions' do
    context 'with an Axis Mundi user' do
      subject { described_class.new(create(:user, :with_axis_mundi_role), record) }

      %i[index show create new update edit destroy].each do |action|
        it { is_expected.to permit_action(action) }
      end
    end

    context 'with a regular user' do
      subject { described_class.new(create(:user), record) }

      %i[index show create new update edit destroy].each do |action|
        it { is_expected.not_to permit_action(action) }
      end
    end

    context 'with a nil user' do
      subject { described_class.new(nil, record) }

      it { is_expected.not_to permit_action(:index) }
      it { is_expected.not_to permit_action(:destroy) }
    end
  end

  describe 'Scope#resolve' do
    let!(:visible_role) { create(:role, kind: 'Scoped Role A') }
    let!(:hidden_role) { create(:role, kind: 'Scoped Role B') }

    it 'returns all records for Axis Mundi users' do
      user = create(:user, :with_axis_mundi_role)
      scope = described_class::Scope.new(user, Role.all).resolve

      expect(scope).to include(visible_role, hidden_role)
    end

    it 'returns no records for regular users' do
      user = create(:user)
      scope = described_class::Scope.new(user, Role.all).resolve

      expect(scope).to be_empty
    end

    it 'returns no records for a nil user' do
      scope = described_class::Scope.new(nil, Role.all).resolve

      expect(scope).to be_empty
    end
  end
end
