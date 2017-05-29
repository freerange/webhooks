require 'bundler/setup'

require 'dotenv'
require 'sinatra'
require 'trello'
require 'mechanize'
require 'airbrake'

require 'json'

require_relative 'lib/harmonia'
require_relative 'lib/trello_event'

Dotenv.load

harmonia_person_names_vs_trello_member_ids = JSON.parse(ENV.fetch('HARMONIA_PERSON_NAMES_VS_TRELLO_MEMBER_IDS'))
set :harmonia_person_names_vs_trello_members, Hash[harmonia_person_names_vs_trello_member_ids.map { |name, id| [name, Trello::Member.new('id' => id)] }]
set :trello_board_id, ENV.fetch('TRELLO_BOARD_ID')
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

configure :production do
  Airbrake.configure do |config|
    config.api_key = ENV.fetch('AIRBRAKE_API_KEY')
    config.host    = ENV.fetch('AIRBRAKE_HOST')
    config.port    = 443
    config.secure  = config.port == 443
    config.ignore << 'Sinatra::NotFound'
  end
  use Airbrake::Sinatra
end

class WebhooksApp < Sinatra::Application
  def initialize(harmonia: nil)
    super(nil)
    @harmonia = harmonia
  end

  get '/' do
    if params[:error]
      raise params[:error]
    else
      [200, 'OK']
    end
  end

  post '/harmonia/assignments' do
    unless params[:token] == settings.authentication_token
      return [401, 'Unauthorized']
    end

    json = request.body.read
    puts json
    attributes = JSON.parse(json)

    assignment = attributes['assignment']
    task, person = assignment['task'], assignment['person']
    member = settings.harmonia_person_names_vs_trello_members[person['name']]

    return if task['done']
    task_url = "https://harmonia.io/t/#{task['key']}"
    task_link = "Harmonia task: #{task_url}"
    card = board.cards.detect { |c| c.desc =~ Regexp.new(task_link) }
    if card
      card.members.each { |m| remove_member_from_card(m, card) }
    else
      description = [task['instructions'], '', task_link].join("\n")
      card = create_card(:name => task['name'], :list_id => list.id, :desc => description)
      create_webhook_for_card(card, :callback_url => "#{settings.trello_events_url}&task_url=#{task_url}")
      update_card(card, :due => task['due_at'], pos: 'bottom')
    end
    add_member_to_card(member, card)

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
    puts json
    event = TrelloEvent.new(JSON.parse(json))

    if event.card_archived?
      @harmonia.mark_as_done(email: settings.harmonia_email, password: settings.harmonia_password, task_url: task_url)

      begin
        card = Trello::Card.find(event.model['id'])
        card.add_comment("Harmonia task marked as done: #{task_url}")
      rescue Trello::Error
        e = RuntimeError.new("Error adding comment to Trello::Card with URL: #{card.short_url}")
        Airbrake.notify_or_ignore(e, parameters: params, cgi_data: settings.environment)
      end
    end

    [200, 'OK']
  end

  private

  def board
    @board ||= Trello::Board.find(settings.trello_board_id)
  rescue Trello::Error
    raise "Error finding Trello::Board for ID: #{settings.trello_board_id}"
  end

  def list
    @list ||= Trello::List.find(settings.trello_list_id)
  rescue Trello::Error
    raise "Error finding Trello::List for ID: #{settings.trello_list_id}"
  end

  def remove_member_from_card(member, card)
    card.remove_member(member)
  rescue Trello::Error
    raise "Error removing #{member.username} from Trello::Card with URL: #{card.short_url}"
  end

  def create_card(attributes)
    Trello::Card.create(attributes)
  rescue Trello::Error
    raise "Error creating Trello::Card with name: #{attributes[:name]}"
  end

  def create_webhook_for_card(card, attributes)
    attributes.merge!(:description => "Watch card #{card.id}", :id_model => card.id)
    Trello::Webhook.create(attributes)
  rescue Trello::Error
    raise "Error creating Trello::Webhook for Trello::Card with URL: #{card.short_url}"
  end

  def update_card(card, attributes)
    attributes.each { |k, v| card.send("#{k}=", v) }
    card.update!
  rescue Trello::Error
    raise "Error setting due date on Trello::Card with URL: #{card.short_url}"
  end

  def add_member_to_card(member, card)
    card.add_member(member)
  rescue Trello::Error
    raise "Error adding #{member.username} to Trello::Card with URL: #{card.short_url}"
  end
end
