require 'rails_helper'

RSpec.describe UserRolePolicy do
  let(:user_with_axis_mundi) { create(:user, :with_axis_mundi_role) }
  let(:regular_user) { create(:user) }
  let(:user_role) { UserRole.first }  # Use the first UserRole created by the :with_axis_mundi_role trait

  shared_examples 'grants access to Axis Mundi role' do |action|
    it "grants access to users with the Axis Mundi role for #{action}" do
      policy = described_class.new(user_with_axis_mundi, user_role)
      expect(policy).to permit_action(action)
    end
  end

  shared_examples 'denies access to regular users' do |action|
    it "denies access to regular users for #{action}" do
      policy = described_class.new(regular_user, user_role)
      expect(policy).not_to permit_action(action)
    end
  end

  describe 'permissions' do
    %i[index show create update destroy].each do |action|
      include_examples 'grants access to Axis Mundi role', action
      include_examples 'denies access to regular users', action
    end
  end
end
