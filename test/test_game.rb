require File.dirname(__FILE__) + '/common'

class TestCards < Test::Unit::TestCase
  include Dominion

  def test_supply
    assert_equal 10, Kingdom.initial_count_in_supply(Village, 2)

    assert_equal 10, Kingdom.initial_count_in_supply(Curse, 2)
    assert_equal 20, Kingdom.initial_count_in_supply(Curse, 3)
    assert_equal 30, Kingdom.initial_count_in_supply(Curse, 4)

    assert_equal  8 + 0*3, Kingdom.initial_count_in_supply(Estate, 0)
    assert_equal  8 + 1*3, Kingdom.initial_count_in_supply(Estate, 1)
    assert_equal  8 + 2*3, Kingdom.initial_count_in_supply(Estate, 2)
    assert_equal 12 + 3*3, Kingdom.initial_count_in_supply(Estate, 3)
    assert_equal 12 + 4*3, Kingdom.initial_count_in_supply(Estate, 4)

    game = Game.new :num_players => 1
  end

  def test_game_state
    game = Game.new :no_setup => true
    assert !game.in_progress?
    
    game.setup
    assert game.in_progress?
    
    game = Game.new
    assert game.in_progress?
    assert_equal 2, game.num_players
    
    game.players.each do |player|
      assert_equal 5, player.hand.size
      assert_equal 5, player.deck.size
    end
  end
  
  def test_player_setup
    game = Game.new :players => [:chloe, :fletcher, :sara]
    
    assert_equal 3, game.num_players

    assert_equal :chloe, game.players[0].identity
    assert_equal 0, game.players[0].position
    
    assert_equal :fletcher, game.players[1].identity
    assert_equal 1, game.players[1].position

    assert_equal :sara, game.players[2].identity
    assert_equal 2, game.players[2].position
    
    game = Game.new :num_players => 4
    assert_equal 4, game.num_players
    game.players.each_with_index do |player, position|
      assert_nil player.identity
      assert_equal position, player.position
    end
  end
  
end
