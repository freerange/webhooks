require 'rubygems'
require 'bundler/setup'

require 'dotenv'
require 'rack/request'
require 'sinatra'
require 'trello'

require 'json'

Dotenv.load

harmonia_person_names_vs_trello_member_ids = JSON.parse(ENV['HARMONIA_PERSON_NAMES_VS_TRELLO_MEMBER_IDS'])

Trello.configure do |config|
  config.developer_public_key = ENV['TRELLO_KEY']
  config.member_token = ENV['TRELLO_TOKEN']
end

post '/harmonia/assignments' do
  json = request.body.read
  attributes = JSON.parse(json)

  assignment = attributes['assignment']
  task_name = assignment['task']['name']
  task_instructions = assignment['task']['instructions']
  task_due_at = assignment['task']['due_at']
  person_name = assignment['person']['name']
  member_id = harmonia_person_names_vs_trello_member_ids[person_name]

  card = Trello::Card.create(:name => task_name, :list_id => ENV['TRELLO_LIST_ID'], :desc => task_instructions, :member_ids => [member_id])
  card.due = task_due_at
  card.update!

  200
end
