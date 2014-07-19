require 'rubygems'
require 'bundler/setup'

require 'dotenv'
require 'sinatra'
require 'trello'

require 'json'
require 'logger'

logger = Logger.new('webhooks.log')

Dotenv.load

harmonia_person_names_vs_trello_member_ids = JSON.parse(ENV.fetch('HARMONIA_PERSON_NAMES_VS_TRELLO_MEMBER_IDS'))
trello_list_id = ENV.fetch('TRELLO_LIST_ID')
authentication_token = ENV.fetch('AUTHENTICATION_TOKEN')
trello_key = ENV.fetch('TRELLO_KEY')
trello_token = ENV.fetch('TRELLO_TOKEN')
trello_secret = ENV.fetch('TRELLO_SECRET')
host = ENV.fetch('HOST')

trello_events_path = '/trello/events'
trello_events_url = "http://#{host}#{path}"

Trello.configure do |config|
  config.developer_public_key = trello_key
  config.member_token = trello_token
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
    task_url = "https://harmonia.io/t/#{task['key']}"
    task_link = "Harmonia task: #{task_url}"
    list = Trello::List.find(trello_list_id)
    card = list.cards.detect { |c| c.desc =~ Regexp.new(task_link) }
    if card
      card.members.each { |m| card.remove_member(m) }
    else
      description = [task['instructions'], '', task_link].join("\n")
      card = Trello::Card.create(:name => task['name'], :list_id => trello_list_id, :desc => description)
      webhook = Trello::Webhook.create(
        :description => "Watch card #{card.id}",
        :id_model => card.id,
        :callback_url => trello_events_url
      )
      card.due = task['due_at']
    end
    card.add_member(Trello::Member.new('id' => member_id))
    card.update!
  end

  [200, 'OK']
end

head trello_events_path do
  [200, 'OK']
end

post trello_events_path do
  body = request.body.read
  data = body + trello_events_url
  hash = OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha1'), trello_secret, data)
  signature = Base64.encode64(hash).chomp
  unless request.env['HTTP_X_TRELLO_WEBHOOK'] == signature
    return [401, 'Unauthorized']
  end

  json = JSON.parse(body)
  logger.info json.inspect

  [200, 'OK']
end
