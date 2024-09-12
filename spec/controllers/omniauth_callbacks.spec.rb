require 'rails_helper'

RSpec.describe Users::OmniauthCallbacksController, type: :controller do
  pending "add some examples to (or delete) #{__FILE__}"
  # let(:user) { create(:user) }

  # describe 'Affiliation management on login' do

  #   before do
  #     mock_login({
  #                  email: user.email,
  #                  name: user.display_name,
  #                  uniqname: user.uniqname
  #                })
  #     session[:urn_values] = [ 'employee', 'student' ]
  #   end

  #   it 'creates new affiliations for the user on login if they do not exist' do
  #     Rails.logger.info("#### Starting Test - Existing affiliations: #{user.affiliations.count}")
  #     expect {
  #       post :saml
  #     }.to change { user.affiliations.count }.by(2)

  #     expect(user.affiliations.map(&:name)).to contain_exactly('employee', 'student')
  #   end

  #   it 'does not duplicate existing affiliations for the user' do
  #     # Add existing affiliation to the user
  #     create(:affiliation, user: user, name: 'employee')

  #     expect {
  #       post :saml
  #     }.to change { user.affiliations.count }.by(1)  # Only 'student' should be created

  #     expect(user.affiliations.map(&:name)).to contain_exactly('employee', 'student')
  #   end

  #   it 'removes affiliations that are no longer reported' do
  #     # Add an affiliation that is not present in the current SAML response
  #     create(:affiliation, user: user, name: 'faculty')

  #     expect {
  #       post :saml
  #     }.to change { user.affiliations.count }.by(1)  # 'faculty' is removed, 'student' added

  #     expect(user.affiliations.map(&:name)).to contain_exactly('employee', 'student')
  #   end
  # end
end
