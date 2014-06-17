require 'rubygems'
require 'bundler/setup'

require 'dotenv'
require 'sinatra'
require 'trello'

require 'json'

Dotenv.load

harmonia_person_names_vs_trello_member_ids = JSON.parse(ENV['HARMONIA_PERSON_NAMES_VS_TRELLO_MEMBER_IDS'])

Trello.configure do |config|
  config.developer_public_key = ENV['TRELLO_KEY']
  config.member_token = ENV['TRELLO_TOKEN']
end

get '/' do
  [200, 'OK']
end

post '/harmonia/assignments' do
  json = request.body.read
  attributes = JSON.parse(json)

  assignment = attributes['assignment']
  task, person = assignment['task'], assignment['person']
  member_id = harmonia_person_names_vs_trello_member_ids[person['name']]

  unless task['done']
    card = Trello::Card.create(:name => task['name'], :list_id => ENV['TRELLO_LIST_ID'], :desc => task['instructions'], :member_ids => [member_id])
    card.due = task['due_at']
    card.update!
  end

  [200, 'OK']
end
