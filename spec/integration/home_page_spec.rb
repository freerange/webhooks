require_relative '../spec_helper'

describe 'home page' do
  def app
    Sinatra::Application
  end

  it 'responds with success status' do
    get '/'
    expect(last_response).to be_ok
  end
end
