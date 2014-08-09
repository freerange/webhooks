require 'bundler/setup'

require 'dotenv'
require 'sinatra'
require 'trello'
require 'mechanize'

require 'json'
require 'logger'

require_relative 'lib/harmonia'
require_relative 'lib/trello_event'

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
set :harmonia_email, ENV.fetch('HARMONIA_EMAIL')
set :harmonia_password, ENV.fetch('HARMONIA_PASSWORD')

set :trello_events_url, "http://#{settings.host}/trello/events?token=#{settings.authentication_token}"

Trello.configure do |config|
  config.developer_public_key = settings.trello_key
  config.member_token = settings.trello_token
end

class WebhooksApp < Sinatra::Application
  def initialize(harmonia: nil)
    super
    @harmonia = harmonia
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
          :callback_url => "#{settings.trello_events_url}&task_url=#{task_url}"
        )
        card.due = task['due_at']
        card.update!
      end
      card.add_member(member)
    end

    [200, 'OK']
  end

  head '/trello/events' do
    [200, 'OK']
  end

  post '/trello/events' do
    if params[:token].nil?
      return [410, 'Gone']
    end
    unless params[:token] == settings.authentication_token
      return [401, 'Unauthorized']
    end
    unless task_url = params['task_url']
      return [400, 'Bad Request']
    end

    json = request.body.read
    event = TrelloEvent.new(JSON.parse(json))

    if event.card_archived?
      @harmonia.mark_as_done(email: settings.harmonia_email, password: settings.harmonia_password, task_url: task_url)
    end

    [200, 'OK']
  end
end
