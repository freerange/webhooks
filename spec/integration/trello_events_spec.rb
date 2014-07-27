require_relative '../spec_helper'

describe 'Trello Events' do
  let(:app) { Sinatra::Application }
  let(:authentication_token) { app.settings.authentication_token }
  let(:body) { {}.to_json }

  it 'responds to head request with success status to allow webhook creation' do
    head '/trello/events'

    expect(last_response).to be_ok
  end

  context 'incorrect authentication token' do
    let(:authentication_token) { app.settings.authentication_token + '-incorrect' }

    it 'responds with 401 Unauthorized' do
      post path, body

      expect(last_response.status).to eq(401)
    end
  end

  context 'missing authentication token' do
    let(:authentication_token) { nil }

    it 'responds with 410 Gone so old webhooks are deleted' do
      post path, body

      expect(last_response.status).to eq(410)
    end
  end

  def path
    "/trello/events" + (authentication_token ? "?token=#{authentication_token}" : '')
  end
end
