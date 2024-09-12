require 'rails_helper'

RSpec.describe Users::OmniauthCallbacksController, type: :controller do
  let(:user) { create(:user) }

  describe 'Affiliation management on login' do
    before do
      allow(request.env).to receive(:[]).and_call_original
      request.env['omniauth.auth'] = OmniAuth::AuthHash.new({
        info: {
          email: user.email,
          uid: user.uid,
          name: user.display_name,
          principal_name: user.principal_name
        },
        extra: {
          raw_info: {
            attributes: {
              'urn:oid:1.3.6.1.4.1.5923.1.1.1.1' => [ 'employee', 'student' ]  # Affiliation data
            }
          }
        }
      })
      session[:urn_values] = [ 'employee', 'student' ]
    end

    it 'creates new affiliations for the user on login if they do not exist' do
      expect {
        post :saml
      }.to change { user.affiliations.count }.by(2)

      expect(user.affiliations.map(&:name)).to contain_exactly('employee', 'student')
    end

    it 'does not duplicate existing affiliations for the user' do
      # Add existing affiliation to the user
      create(:affiliation, user: user, name: 'employee')

      expect {
        post :saml
      }.to change { user.affiliations.count }.by(1)  # Only 'student' should be created

      expect(user.affiliations.map(&:name)).to contain_exactly('employee', 'student')
    end

    it 'removes affiliations that are no longer reported' do
      # Add an affiliation that is not present in the current SAML response
      create(:affiliation, user: user, name: 'faculty')

      expect {
        post :saml
      }.to change { user.affiliations.count }.by(1)  # 'faculty' is removed, 'student' added

      expect(user.affiliations.map(&:name)).to contain_exactly('employee', 'student')
    end
  end
end
