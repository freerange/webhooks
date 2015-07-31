class TrelloCardSorter
  THE_END_OF_DAYS = Time.parse('3000-01-01')

  def initialize(trello_list)
    @trello_list = trello_list
  end

  def sort!
    cards_ordered_by_due_date = @trello_list.cards.sort_by { |c| c.due || THE_END_OF_DAYS }
    cards_ordered_by_due_date.each.with_index do |card, index|
      card.pos = index
      card.update!
    end
  end
end
