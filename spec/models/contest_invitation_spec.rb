# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ContestInvitation, type: :model do
  it 'normalizes email to lowercase' do
    invitation = create(:contest_invitation, email: 'Applicant@Umich.Edu')
    expect(invitation.email).to eq('applicant@umich.edu')
  end

  it 'requires a unique email per contest instance' do
    invitation = create(:contest_invitation)
    duplicate = build(:contest_invitation,
                      contest_instance: invitation.contest_instance,
                      email: invitation.email.upcase)

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:email]).to be_present
  end

  it 'allows the same email on different contest instances' do
    invitation = create(:contest_invitation)
    other = build(:contest_invitation, email: invitation.email)

    expect(other).to be_valid
  end
end
