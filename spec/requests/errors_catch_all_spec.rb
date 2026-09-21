# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Catch-all unknown path routing', type: :request do
  # PR #264 limited the catch-all to GET/HEAD so unknown POSTs never hit
  # ErrorsController (which no longer skips forgery protection).
  # Assert routing directly — rendering the 404 template needs built CSS assets.

  it 'routes unknown GET paths to ErrorsController#not_found' do
    expect(Rails.application.routes.recognize_path('/definitely-not-a-real-page', method: :get))
      .to include(controller: 'errors', action: 'not_found')
  end

  it 'routes unknown HEAD paths to ErrorsController#not_found' do
    expect(Rails.application.routes.recognize_path('/definitely-not-a-real-page', method: :head))
      .to include(controller: 'errors', action: 'not_found')
  end

  it 'does not route unknown POST requests through the catch-all ErrorsController' do
    expect {
      Rails.application.routes.recognize_path('/definitely-not-a-real-page', method: :post)
    }.to raise_error(ActionController::RoutingError)
  end
end
