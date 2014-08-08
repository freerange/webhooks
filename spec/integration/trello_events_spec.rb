require_relative '../spec_helper'

require 'addressable/uri'

describe 'Trello Events' do
  let(:app) { WebhooksApp.new }
  let(:authentication_token) { app.settings.authentication_token }
  let(:harmonia_credentials) { { email: app.settings.harmonia_email, password: app.settings.harmonia_password } }
  let(:team_key) { 'h54uvc' }
  let(:task_key) { '8b704a' }
  let(:task_url) { "https://harmonia.io/t/#{task_key}" }
  let(:task_done_path) { "/teams/#{team_key}/tasks/#{task_key}/done" }
  let(:task_done_url) { "https://harmonia.io#{task_done_path}" }
  let(:body) { { action: { type: 'updateCard', data: { old: { closed: false } } }, model: { closed: true } }.to_json }

  it 'responds to head request with success status to allow webhook creation' do
    head path

    expect(last_response).to be_ok
  end

  it 'marks Harmonia task as done' do
    stub_request(:get, 'https://harmonia.io/sign-in').to_return(success(body: sign_in_page))
    stub_request(:post, 'https://harmonia.io/session').with(body: harmonia_credentials).to_return(success)
    stub_request(:get, task_url).to_return(success(body: task_page))
    stub_request(:post, task_done_url).to_return(success)

    post path, body

    expect(a_request(:post, task_done_url)).to have_been_made
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

  def sign_in_page
    html_page(%{
      <form action="/session" method="post">
        <input name="email" type="text"/>
        <input name="password" type="password"/>
      </form>
    })
  end

  def task_page
    html_page(%{
      <form action="#{task_done_path}" method="post">
      </form>
    })
  end

  def html_page(body)
    %{
      <html>
        <head></head>
        <body>
          #{body}
        </body>
      </html>
    }
  end

  def success(options = {})
    { body: '', status: 200, headers: { 'Content-Type' => 'text/html'} }.merge(options)
  end
end
