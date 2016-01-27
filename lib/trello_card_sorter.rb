class TrelloCardSorter
  THE_END_OF_DAYS = Time.parse('3000-01-01')

  def initialize(trello_list)
    @trello_list = trello_list
  end

  def sort!
    @trello_list.cards.select(&:due).sort_by(&:due).reverse.each do |card|
      card.pos = 'top'
      card.update!
    end
  end
end
