ENV['RACK_ENV'] = 'test'
require_relative '../app.rb'
require 'rspec'
require 'rack/test'
require 'webmock/rspec'

RSpec.configure do |config|
  config.include Rack::Test::Methods
end

WebMock.disable_net_connect!
