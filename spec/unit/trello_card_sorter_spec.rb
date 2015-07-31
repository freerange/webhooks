require_relative '../spec_helper'

describe 'Trello Card Sorter' do
  let(:card_not_due) { double(:card_not_due, due: nil) }
  let(:card_due_later) { double(:card_due_later, due: Time.parse("2000-01-02 00:00:00")) }
  let(:card_due_earlier) { double(:card_due_earlier, due: Time.parse("2000-01-01 00:00:00")) }
  let(:trello_list) { double(:trello_list, cards: [card_not_due, card_due_later, card_due_earlier]) }

  subject { TrelloCardSorter.new(trello_list) }

  it 'sort cards into chronological order' do
    expect(card_due_earlier).to receive(:pos=).with(0)
    expect(card_due_earlier).to receive(:update!).ordered

    expect(card_due_later).to receive(:pos=).with(1)
    expect(card_due_later).to receive(:update!).ordered

    expect(card_not_due).to receive(:pos=).with(2).ordered
    expect(card_not_due).to receive(:update!).ordered

    subject.sort!
  end
end