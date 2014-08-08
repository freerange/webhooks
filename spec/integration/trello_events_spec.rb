require_relative '../spec_helper'

require 'addressable/uri'

describe 'Trello Events' do
  let(:harmonia) { double(:harmonia) }
  let(:app) { WebhooksApp.new(harmonia: harmonia) }
  let(:authentication_token) { app.settings.authentication_token }
  let(:task_key) { '8b704a' }
  let(:task_url) { "https://harmonia.io/t/#{task_key}" }
  let(:body) { { action: { type: 'updateCard', data: { old: { closed: false } } }, model: { closed: true } }.to_json }

  it 'responds to HEAD request with success status to allow webhook creation' do
    head path

    expect(last_response).to be_ok
  end

  it 'marks Harmonia task as done' do
    expect(harmonia).to receive(:mark_as_done).with(email: app.settings.harmonia_email, password: app.settings.harmonia_password, task_url: task_url)

    post path, body
  end

  it 'responds to POST request with success status' do
    allow(harmonia).to receive(:mark_as_done)

    post path, body

    expect(last_response).to be_ok
  end

  context 'missing task url' do
    let(:task_url) { nil }

    it 'responds with 400 Bad Request' do
      post path, body

      expect(last_response.status).to eq(400)
    end
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
    uri = Addressable::URI.parse('/trello/events')
    values = {}
    values[:token] = authentication_token if authentication_token
    values[:task_url] = task_url if task_url
    uri.query_values = values
    uri.to_s
  end
end
