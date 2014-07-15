require 'rubygems'
require 'bundler/setup'

require 'dotenv'
require 'sinatra'
require 'trello'

require 'json'

Dotenv.load

harmonia_person_names_vs_trello_member_ids = JSON.parse(ENV.fetch('HARMONIA_PERSON_NAMES_VS_TRELLO_MEMBER_IDS'))
trello_list_id = ENV.fetch('TRELLO_LIST_ID')
authentication_token = ENV.fetch('AUTHENTICATION_TOKEN')

Trello.configure do |config|
  config.developer_public_key = ENV.fetch('TRELLO_KEY')
  config.member_token = ENV.fetch('TRELLO_TOKEN')
end

get '/' do
  [200, 'OK']
end

post '/harmonia/assignments' do
  unless params[:token] == authentication_token
    return [401, 'Unauthorized']
  end

  json = request.body.read
  attributes = JSON.parse(json)

  assignment = attributes['assignment']
  task, person = assignment['task'], assignment['person']
  member_id = harmonia_person_names_vs_trello_member_ids[person['name']]

  unless task['done']
    card = Trello::Card.create(:name => task['name'], :list_id => trello_list_id, :desc => task['instructions'])
    card.due = task['due_at']
    card.add_member(Trello::Member.new('id' => member_id))
    card.update!
  end

  [200, 'OK']
end
