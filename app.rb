require 'bundler/setup'

require 'dotenv'
require 'sinatra'
require 'trello'

require 'json'
require 'logger'

logger = Logger.new(File.expand_path('../log/webhooks.log', __FILE__))

Dotenv.load

harmonia_person_names_vs_trello_member_ids = JSON.parse(ENV.fetch('HARMONIA_PERSON_NAMES_VS_TRELLO_MEMBER_IDS'))
set :harmonia_person_names_vs_trello_members, Hash[harmonia_person_names_vs_trello_member_ids.map { |name, id| [name, Trello::Member.new('id' => id)] }]
set :trello_list_id, ENV.fetch('TRELLO_LIST_ID')
set :authentication_token, ENV.fetch('AUTHENTICATION_TOKEN')
set :trello_key, ENV.fetch('TRELLO_KEY')
set :trello_token, ENV.fetch('TRELLO_TOKEN')
set :trello_secret, ENV.fetch('TRELLO_SECRET')
set :host, ENV.fetch('HOST')

set :trello_events_path, '/trello/events'
set :trello_events_url, "http://#{settings.host}#{settings.trello_events_path}"

Trello.configure do |config|
  config.developer_public_key = settings.trello_key
  config.member_token = settings.trello_token
end

get '/' do
  [200, 'OK']
end

post '/harmonia/assignments' do
  unless params[:token] == settings.authentication_token
    return [401, 'Unauthorized']
  end

  json = request.body.read
  attributes = JSON.parse(json)

  assignment = attributes['assignment']
  task, person = assignment['task'], assignment['person']
  member = settings.harmonia_person_names_vs_trello_members[person['name']]

  unless task['done']
    task_url = "https://harmonia.io/t/#{task['key']}"
    task_link = "Harmonia task: #{task_url}"
    list = Trello::List.find(settings.trello_list_id)
    card = list.cards.detect { |c| c.desc =~ Regexp.new(task_link) }
    if card
      card.members.each { |m| card.remove_member(m) }
    else
      description = [task['instructions'], '', task_link].join("\n")
      card = Trello::Card.create(:name => task['name'], :list_id => list.id, :desc => description)
      webhook = Trello::Webhook.create(
        :description => "Watch card #{card.id}",
        :id_model => card.id,
        :callback_url => settings.trello_events_url
      )
      card.due = task['due_at']
      card.update!
    end
    card.add_member(member)
  end

  [200, 'OK']
end

head settings.trello_events_path do
  [200, 'OK']
end

post settings.trello_events_path do
  body = request.body.read
  data = body + settings.trello_events_url
  hash = OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha1'), settings.trello_secret, data)
  signature = Base64.encode64(hash).chomp
  unless request.env['HTTP_X_TRELLO_WEBHOOK'] == signature
    return [401, 'Unauthorized']
  end

  json = JSON.parse(body)
  logger.info json.inspect

  if ((action = json['action']) && (action['type'] == 'updateCard')) && ((data = action['data']) && (old = data['old']) && (old['closed'] == false)) && ((model = json['model']) && (model['closed'] == true))
    logger.info '*** archived ***'
  end

  [200, 'OK']
end
