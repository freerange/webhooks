ENV['RACK_ENV'] = 'test'
require_relative '../app.rb'
require 'rspec'
require 'rack/test'

RSpec.configure do |config|
  config.include Rack::Test::Methods
end
