require_relative '../spec_helper'

describe 'Trello Event' do
  let(:attributes) { { 'action' => { 'type' => 'updateCard', 'data' => { 'old' => { 'closed' => false } } }, 'model' => { 'closed' => true } } }
  subject { TrelloEvent.new(attributes) }

  it 'indicates event was card being archived' do
    expect(subject).to be_card_archived
  end

  context "event action is not 'updateCard'" do
    let(:attributes) { { 'action' => { 'type' => 'deleteCard' } } }

    it 'indicates event was not card being archived' do
      expect(subject).to_not be_card_archived
    end
  end

  context "event action is missing 'data' attribute" do
    let(:attributes) { { 'action' => { 'type' => 'updateCard' }, 'model' => { 'closed' => true } } }

    it 'indicates event was not card being archived' do
      expect(subject).to_not be_card_archived
    end
  end

  context "event action is missing 'model' attribute" do
    let(:attributes) { { 'action' => { 'type' => 'updateCard', 'data' => { 'old' => { 'closed' => false } } } } }

    it 'indicates event was not card being archived' do
      expect(subject).to_not be_card_archived
    end
  end

  context 'card was already archived' do
    let(:attributes) { { 'action' => { 'type' => 'updateCard', 'data' => { 'old' => { 'closed' => true } } }, 'model' => { 'closed' => true } } }

    it 'indicates event was not card being archived' do
      expect(subject).to_not be_card_archived
    end
  end

  context 'card was not archived' do
    let(:attributes) { { action: { type: 'updateCard', data: { old: { closed: false } } }, model: { closed: false } } }

    it 'indicates event was not card being archived' do
      expect(subject).to_not be_card_archived
    end
  end
end
