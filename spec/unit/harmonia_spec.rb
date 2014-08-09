require_relative '../spec_helper'

describe 'Harmonia' do
  subject { Harmonia.new }
  let(:email) { 'harmonia-email' }
  let(:password) { 'harmonia-password' }
  let(:team_key) { 'h54uvc' }
  let(:task_key) { '8b704a' }
  let(:task_url) { "https://harmonia.io/t/#{task_key}" }
  let(:task_done_path) { "/teams/#{team_key}/tasks/#{task_key}/done" }
  let(:task_done_url) { "https://harmonia.io#{task_done_path}" }

  before do
    stub_request(:get, 'https://harmonia.io/sign-in').to_return(success(body: sign_in_page))
    stub_request(:post, 'https://harmonia.io/session').with(body: { email: email, password: password }).to_return(success)
    stub_request(:get, task_url).to_return(success(body: task_page))
    stub_request(:post, task_done_url).to_return(success)
  end

  it 'marks a task as done' do
    subject.mark_as_done(email: email, password: password, task_url: task_url)

    expect(a_request(:post, task_done_url)).to have_been_made
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
