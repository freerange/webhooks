require_relative '../spec_helper'

describe 'Trello Card Sorter' do
  let(:card_not_due) { double(:card_not_due, due: nil) }
  let(:card_due_later) { double(:card_due_later, due: Time.parse("2000-01-02 00:00:00")) }
  let(:card_due_earlier) { double(:card_due_earlier, due: Time.parse("2000-01-01 00:00:00")) }
  let(:trello_list) { double(:trello_list, cards: [card_not_due, card_due_later, card_due_earlier]) }

  subject { TrelloCardSorter.new(trello_list) }

  it 'moves cards with earliest due dates nearest the top' do
    expect(card_due_later).to receive(:pos=).with('top')
    expect(card_due_later).to receive(:update!).ordered

    expect(card_due_earlier).to receive(:pos=).with('top')
    expect(card_due_earlier).to receive(:update!).ordered

    expect(card_not_due).not_to receive(:update!)

    subject.sort!
  end
end
