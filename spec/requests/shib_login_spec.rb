# # frozen_string_literal: true

# require 'rails_helper'

# RSpec.describe 'Shibboleth' do
#   let(:user) { create(:user, :employee) }

#   describe 'login success -' do
#     before do
#       mock_login({
#                    email: user.email,
#                    name: user.display_name,
#                    uniqname: user.uniqname
#                  })
#     end

#     it 'displays user avatar' do
#       expect(response).to be_redirect
#       follow_redirect!
#       expect(response.body).to include('id="avatar"')
#       expect(response.body).to include(user.display_name)
#     end
#   end

#   describe 'login failure -' do
#     before do
#       mock_login({
#                    email: 'kielbasa',
#                    name: user.display_name,
#                    uniqname: user.uniqname
#                  })
#     end

#     it 'does not display user avatar' do
#       expect(response.body).not_to include('id="avatar"')
#     end
#   end
# end
