require File.dirname(__FILE__) + '/common'

class TestCards < Test::Unit::TestCase
  include Dominion

  class Game
    attr_accessor :buy_phase, :actions_played
    def buy_phase?
      buy_phase
    end
  end

  def test_simple_card
    v = Village.new

    assert_equal 2, v.actions
    assert_equal 1, v.cards
    assert_equal 0, v.buys
  end

  def test_peddler
    p = Peddler.new
    game = Game.new

    game.buy_phase = true
    game.actions_played = 5
    assert_equal 0, p.cost(game)
    
    game.buy_phase = false
    assert_equal 8, p.cost(game)
    
    game.buy_phase = true
    game.actions_played = 0
    assert_equal 8, p.cost(game)
    
    game.actions_played = 2
    assert_equal 4, p.cost(game)
  end
  
  def test_cards
    all_cards = Card.all_cards
  end

end

