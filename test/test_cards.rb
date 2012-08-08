require File.dirname(__FILE__) + '/common'

class TestCards < Test::Unit::TestCase

  class MockGame
    attr_accessor :buy_phase, :actions_in_play

    def buy_phase?
      buy_phase
    end
    
    def durations_in_play
      []
    end
  end
  
  def setup
    @game = MockGame.new
  end
  
  def test_simple_card
    assert Village.action?
    assert Village.kingdom?
    assert !Village.victory?
    
    v = Village.new

    assert_equal 2, v.actions
    assert_equal 1, v.cards
    assert_equal 0, v.buys
    
    assert v.action?
    assert v.kingdom?
    assert !v.victory?
    assert !v.base?
  end

  def test_peddler
    # out of context
    p = Peddler.new
    assert_equal 8, p.cost

    # in game context
    p = Peddler.new @game

    @game.buy_phase = true
    @game.actions_in_play = Array.new 5
    assert_equal 0, p.cost
    
    @game.buy_phase = false
    assert_equal 8, p.cost
    
    @game.buy_phase = true
    @game.actions_in_play = []
    assert_equal 8, p.cost
    
    @game.actions_in_play = Array.new 2
    assert_equal 4, p.cost
  end

  def test_get_all_cards
    all_cards = Dominion.all_cards
  end

end

