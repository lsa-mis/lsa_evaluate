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

    it 'resolves an opaque encrypted SAML RelayState without exposing the path' do
      opaque = controller.send(:stash_saml_return_path!, '/c/private-contest-token')
      allow(controller.request).to receive(:params).and_return(
        ActionController::Parameters.new('RelayState' => opaque)
      )

      expect(opaque).to start_with('sr_')
      expect(opaque).not_to include('private-contest-token')
      expect(controller.send(:after_sign_in_path_for, judge)).to eq('/c/private-contest-token')
    end

    it 'ignores a tampered opaque RelayState' do
      allow(controller.request).to receive(:params).and_return(
        ActionController::Parameters.new('RelayState' => 'sr_not-a-valid-payload')
      )

      expect(controller.send(:after_sign_in_path_for, judge)).to eq(judge_dashboard_path)
    end

    it 'uses a direct omniauth.origin path when RelayState is absent' do
      request.env['omniauth.origin'] = '/entries/new'

      expect(controller.send(:after_sign_in_path_for, judge)).to eq('/entries/new')
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

  describe '#saml_authorize_params' do
    it 'passes an opaque origin instead of the raw return path' do
      session['user_return_to'] = '/c/secret-invite-token'

      params = controller.saml_authorize_params

      expect(params[:origin]).to start_with('sr_')
      expect(params[:origin]).not_to include('secret-invite-token')
    end

    it 'returns an empty hash when there is no stored return path' do
      expect(controller.saml_authorize_params).to eq({})
    end
  end
end
