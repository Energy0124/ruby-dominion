require File.dirname(__FILE__) + '/common'

class TestGame < Test::Unit::TestCase

  def test_basic_play
    game = Game.new :num_players => 1
    player = game.current_player
    
    assert game.action_phase?
    assert_equal 1, player.actions_available
    assert_equal 1, player.buys_available
    assert_equal 0, player.coins_available
    
    player.play_all_treasures
    assert game.treasure_phase?
    assert player.coins_available >= 2    # even with random deck, at least a 5/2 opening
    coppers = player.coins_available
    assert_equal 5 - coppers, player.hand.size
    assert_equal coppers, player.treasures_in_play.size
    
    player.buy Estate
    assert game.buy_phase?
    assert_equal coppers - 2, player.coins_available    # Estate costs 2
    assert_equal 0, player.buys_available
    
    player.end_turn
    assert game.action_phase?
  end
  
  def test_winner
    game = Game.new :no_cards => true

    game.players[0].gain Estate
    assert_equal game.players[0], game.winner
    game.players[1].gain Duchy
    assert_equal game.players[1], game.winner
    game.players[0].gain Duchy
    assert_equal game.players[0], game.winner
    game.players[1].gain Province
    assert_equal game.players[1], game.winner
  end
  
  def test_ask_using_chancellor
    game = Game.new :num_players => 1, :kingdom_cards => [Chancellor]
    player = game.current_player
    
    assert_equal 5, player.deck.size

    # synchronous, using :choice
    player.gain Chancellor, :to => :hand
    player.play Chancellor, :choice => true
    assert !player.choice_in_progress, "should not be waiting for choice"
    assert_equal 0, player.deck.size
    player.end_turn
  end

  def test_choose_one_using_nobles
    game = Game.new :num_players => 1, :kingdom_cards => [Nobles]
    player = game.current_player

    # choose actions
    player.gain Nobles, :to => :hand
    orig_hand_size = player.hand.size
    player.play Nobles, :choice => :cards
    assert_equal orig_hand_size + 2, player.hand.size
    player.end_turn

    # choose cards
    player.gain Nobles, :to => :hand
    player.play Nobles, :choice => :actions
    assert_equal 2, player.actions_available
    player.end_turn
  end
  
  def test_choose_card_using_salvager
    game = Game.new :num_players => 1, :no_cards => true, :kingdom_cards => [Salvager]
    player = game.current_player
    
    # synchronous, using Card class
    coins = player.coins_available
    player.gain Salvager, :to => :hand
    player.gain Estate, :to => :hand
    player.play Salvager, :choice => Estate
    assert_equal coins + 2, player.coins_available
    player.end_turn
    
    # synchronous, using card instance
    coins = player.coins_available
    player.gain Salvager, :to => :hand
    estate = player.gain Estate, :to => :hand
    player.play Salvager, :choice => estate
    assert_equal coins + 2, player.coins_available
    player.end_turn
  end
  
  def test_choose_cards_using_chapel
    game = Game.new :num_players => 1, :no_cards => true, :kingdom_cards => [Chapel]
    player = game.current_player
    
    # synchronous, using :choice => [Card, Card]
    player.gain Chapel, :to => :hand
    player.gain Estate, :to => :hand
    player.gain Estate, :to => :hand
    player.gain Copper, :to => :hand
    player.gain Copper, :to => :hand
    player.play Chapel, :choice => [Estate, Estate, Copper]
    assert_equal 1, player.hand.size
    player.play_all_treasures
    assert_equal 1, player.coins_available
    player.end_turn
    
    # synchronous, using :choice => Card
    player.hand.clear
    player.gain Chapel, :to => :hand
    player.gain Estate, :to => :hand
    player.gain Estate, :to => :hand
    player.gain Copper, :to => :hand
    player.gain Copper, :to => :hand
    player.play Chapel, :choice => Estate
    assert_equal 3, player.hand.size
    player.play_all_treasures
    assert_equal 2, player.coins_available
    player.end_turn
  end
  
  def test_no_choice_using_moneylender
    game = Game.new :num_players => 1, :no_cards => true, :kingdom_cards => [Moneylender]
    player = game.current_player
    
    # play Moneylender when no Copper in hand
    player.gain Moneylender, :to => :hand
    player.gain Estate, :to => :hand
    player.play Moneylender
    player.play_all_treasures
    assert_equal 0, player.coins_available
    player.end_turn

    # play Moneylender when Copper is in hand
    player.gain Moneylender, :to => :hand
    player.gain Copper, :to => :hand
    player.gain Copper, :to => :hand
    player.play Moneylender
    player.play_all_treasures
    assert_equal 4, player.coins_available
    player.end_turn
  end

  def test_attack_with_reactions_using_minion_and_moat
    game = Game.new :num_players => 3, :kingdom_cards => [Minion, Moat]
    player = game.current_player
    player2 = game.players[1]
    player3 = game.players[2]

    player.gain Minion, :to => :hand
    player2.gain Moat, :to => :hand

    player2.strategy = MockStrategy.new([true])    # reveal Moat when attacked

    player.play Minion, :choice => :discard

    assert_equal 4, player.hand.size
    assert_equal 6, player2.hand.size       # revealed Moat  (5 + Moat)
    assert_equal 4, player3.hand.size       # no Moat
  end

  def test_durations_with_throne_room_and_kings_court
    # TR, KC(2), [FV(3), FV(3)], FV, KC, M(3)
    game = Game.new :num_players => 1, :no_cards => true, :kingdom_cards => [ThroneRoom, KingsCourt, FishingVillage, Monument]
    player = game.current_player

    player.gain [FishingVillage, FishingVillage, FishingVillage, ThroneRoom, KingsCourt, KingsCourt, Monument], :to => :hand
    player.strategy = MockStrategy.new([KingsCourt, FishingVillage, FishingVillage, Monument])
    player.play ThroneRoom
    player.play FishingVillage
    player.play KingsCourt
    assert player.strategy.done?, "Strategy not entirely played: #{player.strategy}"

    assert_equal 2*3*1 + 1 + 3*2, player.coins_available
    assert_equal 2*3*2 + 2 - 2, player.actions_available
    player.end_turn
    assert_equal 2*3*1 + 1, player.coins_available
    assert_equal 2*3*1 + 1 + 1, player.actions_available
    assert_equal 4, player.actions_in_play_from_previous_turn.count

    # KC, TR(3), KC(2), [M(3), M(3)], M(2), FV(2), FV
    game = Game.new :num_players => 1, :no_cards => true, :kingdom_cards => [ThroneRoom, KingsCourt, FishingVillage, Monument]
    player = game.current_player

    player.gain [FishingVillage, FishingVillage, FishingVillage, ThroneRoom, KingsCourt, KingsCourt, Monument, Monument, Monument], :to => :hand
    player.strategy = MockStrategy.new([ThroneRoom, KingsCourt, Monument, Monument, Monument, FishingVillage])
    player.play KingsCourt
    player.play FishingVillage
    assert player.strategy.done?, "Strategy not entirely played: #{player.strategy}"

    assert_equal 2*3*2 + 2*2 + 2*1 + 1, player.coins_available
    assert_equal 2*1*2 + 2 - 1, player.actions_available
    player.end_turn
    assert_equal 2*1*1 + 1, player.coins_available
    assert_equal 1 + 2*1*1 + 1, player.actions_available
    assert_equal 3, player.actions_in_play_from_previous_turn.count
  end

  def test_attack_with_witch_and_lighthouse
    game = Game.new :num_players => 3, :kingdom_cards => [Witch, Lighthouse]
    p1 = game.current_player
    p2 = game.players[1]
    p3 = game.players[2]

    p1.gain Lighthouse, :to => :hand
    p1.play Lighthouse
    p1.end_turn
    assert_has_a Lighthouse, p1.actions_in_play_from_previous_turn

    p2.gain Witch, :to => :hand
    p2.play Witch

    assert_has_no Curse, p1.discard_pile
    assert_has_no Curse, p2.discard_pile
    assert_has_a Curse, p3.discard_pile
  end

end
