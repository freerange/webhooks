require_relative '../spec_helper'

describe 'Harmonia Assignments' do
  let(:app) { WebhooksApp.new }
  let(:authentication_token) { app.settings.authentication_token }
  let(:person) { { name: 'James Mead' } }
  let(:task) { { name: 'task-name', key: 'abc123', instructions: 'task-instructions', due_at: "2014-07-05T17:00:00.000+01:00", done: false } }
  let(:task_url) { "https://harmonia.io/t/#{task[:key]}" }
  let(:task_link) { "Harmonia task: #{task_url}" }
  let(:body) { { assignment: { task: task, person: person } }.to_json }
  let(:cards) { [] }
  let(:list) { double(:trello_list, id: app.settings.trello_list_id, cards: cards) }
  let(:card) { double(:trello_card, id: 'def456').as_null_object }

  before do
    allow(Trello::List).to receive(:find).and_return(list)
    allow(Trello::Card).to receive(:create).and_return(card)
    allow(Trello::Webhook).to receive(:create)
  end

  it 'creates a new Trello card corresponding to the Harmonia task' do
    expect(Trello::Card).to receive(:create).with(name: 'task-name', list_id: list.id, desc: include(task[:instructions]).and(include(task_link)))

    post path, body
  end

  it 'creates a new Trello webhook to monitor the newly created Trello card' do
    expect(Trello::Webhook).to receive(:create).with(include(id_model: card.id, callback_url: "#{app.settings.trello_events_url}&task_url=#{task_url}"))

    post path, body
  end

  it 'updates the newly created Trello card corresponding to the Harmonia task' do
    expect(card).to receive(:due=).with(task[:due_at])
    expect(card).to receive(:update!)

    post path, body
  end

  it 'adds the assignee as a member of the newly created Trello card' do
    member = app.settings.harmonia_person_names_vs_trello_members[person[:name]]
    expect(card).to receive(:add_member).with(member)

    post path, body
  end

  it 'sorts the cards into chronological order' do
    trello_card_sorter = double(:trello_card_sorter)
    allow(TrelloCardSorter).to receive(:new).and_return(trello_card_sorter)
    expect(trello_card_sorter).to receive(:sort!)

    post path, body
  end

  it 'responds with 200 OK' do
    post path, body

    expect(last_response.status).to eq(200)
  end

  context 'Trello card for task already exists' do
    let(:member_one) { double(:member) }
    let(:member_two) { double(:member) }
    let(:existing_card) { double(:existing_card, desc: task_link, members: [member_one, member_two]) }
    let(:cards) { [existing_card] }

    before do
      allow(existing_card).to receive(:remove_member)
      allow(existing_card).to receive(:add_member)
    end

    it 'removes all members of existing card' do
      expect(existing_card).to receive(:remove_member).with(member_one)
      expect(existing_card).to receive(:remove_member).with(member_two)

      post path, body
    end

    it 'adds the assignee as a member of the existing Trello card' do
      member = app.settings.harmonia_person_names_vs_trello_members[person[:name]]
      expect(existing_card).to receive(:add_member).with(member)

      post path, body
    end
  end

  context 'Harmonia assignment is already done' do
    let(:task) { { done: true } }

    it 'responds with 200 OK' do
      post path, body

      expect(last_response.status).to eq(200)
    end

    it 'does not create a Trello card' do
      post path, body

      expect(Trello::Card).not_to receive(:create)
    end

    it 'does not create a Trello webhook' do
      post path, body

      expect(Trello::Webhook).not_to receive(:create)
    end
  end

  context 'incorrect authentication token' do
    let(:authentication_token) { app.settings.authentication_token + '-incorrect' }

    it 'responds with 401 Unauthorized' do
      post path, body

      expect(last_response.status).to eq(401)
    end
  end

  def path
    "/harmonia/assignments?token=#{authentication_token}"
  end
end
