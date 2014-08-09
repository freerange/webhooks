class TrelloEvent
  def initialize(attributes)
    @attributes = attributes
  end

  def action
    @attributes['action'] || {}
  end

  def data
    action['data'] || {}
  end

  def old_data
    data['old'] || {}
  end

  def model
    @attributes['model'] || {}
  end

  def card_archived?
    (action['type'] == 'updateCard') &&
      (old_data['closed'] == false) &&
      (model['closed'] == true)
  end
end
