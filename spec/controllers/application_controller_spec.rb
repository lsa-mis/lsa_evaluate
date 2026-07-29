# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationController, type: :controller do
  controller do
    def index
      head :ok
    end
  end

  describe '#after_sign_in_path_for' do
    let(:judge) { create(:user, :with_judge_role) }

    it 'uses SAML RelayState before the role-based default' do
      allow(controller.request).to receive(:params).and_return(
        ActionController::Parameters.new('RelayState' => '/c/private-contest-token')
      )

      expect(controller.send(:after_sign_in_path_for, judge)).to eq('/c/private-contest-token')
    end

    it 'uses omniauth.origin when RelayState is absent' do
      request.env['omniauth.origin'] = '/c/from-omniauth-origin'

      expect(controller.send(:after_sign_in_path_for, judge)).to eq('/c/from-omniauth-origin')
    end

    it 'uses the stored destination before the role-based default' do
      session['user_return_to'] = '/c/private-contest-token'

      expect(controller.send(:after_sign_in_path_for, judge)).to eq('/c/private-contest-token')
    end

    it 'rejects external RelayState values' do
      allow(controller.request).to receive(:params).and_return(
        ActionController::Parameters.new('RelayState' => 'https://evil.example/phish')
      )

      expect(controller.send(:after_sign_in_path_for, judge)).to eq(judge_dashboard_path)
    end

    it 'ignores homepage RelayState so judges still land on the dashboard' do
      allow(controller.request).to receive(:params).and_return(
        ActionController::Parameters.new('RelayState' => '/')
      )
      request.env['omniauth.origin'] = '/'

      expect(controller.send(:after_sign_in_path_for, judge)).to eq(judge_dashboard_path)
    end

    it 'uses the role-based default without a stored destination' do
      expect(controller.send(:after_sign_in_path_for, judge)).to eq(judge_dashboard_path)
    end
  end
end
