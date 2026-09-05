# frozen_string_literal: true

require 'rails_helper'

RSpec.describe JudgeDashboardPolicy do
  subject { described_class.new(user, :judge_dashboard) }

  describe '#index?' do
    context 'when the user has the Judge role' do
      let(:user) { create(:user, :with_judge_role) }

      it { is_expected.to permit_action(:index) }
    end

    context 'when the user is an employee without the Judge role' do
      let(:user) { create(:user, :employee) }

      it { is_expected.not_to permit_action(:index) }
    end

    context 'when the user is nil' do
      let(:user) { nil }

      it { is_expected.not_to permit_action(:index) }
    end
  end
end
