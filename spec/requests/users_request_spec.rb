# frozen_string_literal: true
require 'rails_helper'

RSpec.describe "Users", type: :request do
  describe "GET /users/auth/cas/callback" do
    context 'without being authenticated' do
      before do
        get user_cas_omniauth_callback_path
      end

      it 'builds the callback from the CAS endpoint response' do
        expect(response.status).to eq(302)
        expect(response).to redirect_to(new_user_session_url)
      end
    end

    context 'with a valid user' do
      let(:user) { create(:user) }
      let(:ticket) { '593af' }
      let(:cas_url) do
        "#{Rails.application.config.cas.url}/serviceValidate?service=#{user_cas_omniauth_callback_url}?&ticket=#{ticket}"
      end

      before do
        login_as(user)
        stub_request(
          :get,
          cas_url
        ).to_return(
          headers: {},
          status: 200,
          body: File.read(Rails.root.join('spec', 'fixtures', 'omniauth-cas', 'cas_success.xml'))
        )
        allow(User).to receive(:from_omniauth).and_return(user)

        get user_cas_omniauth_authorize_path
      end

      after do
        logout
      end

      it 'builds the callback from the CAS endpoint response' do
        expect(response.status).to eq(302)
        expect(response.headers['Location']).to include(Rails.application.config.cas.url)

        get "#{user_cas_omniauth_callback_path}?ticket=#{ticket}"

        expect(response).to redirect_to(root_url)
      end
    end
  end
end
