require 'card'

module Dominion
  
  #
  # Base cards
  #

  # Copper, Silver, Gold, Platinum, Potion
  # Estate, Duchy, Province, Colony
  # Curse
  
  class Copper < Card
    set :base
    type :base, :treasure
    cost 0
    coins 1
  end

  class Silver < Card
    set :base
    type :base, :treasure
    cost 3
    coins 2
  end

  class Gold < Card
    set :base
    type :base, :treasure
    cost 6
    coins 3
  end

  class Platinum < Card
    set :prosperity
    type :base, :treasure
    cost 9
    coins 5
  end
  
  class Potion < Card
    set :alchemy
    type :base, :treasure
    cost 4
  end

  class Estate < Card
    set :base
    type :base, :victory
    cost 2
    vp 1
  end

  class Duchy < Card
    set :base
    type :base, :victory
    cost 5
    vp 3
  end

  class Province < Card
    set :base
    type :base, :victory
    cost 8
    vp 6
  end

  class Colony < Card
    set :prosperity
    type :base, :victory
    cost 11
    vp 10
  end

  class Curse < Card
    set :base
    type :base, :curse
    cost 0
    vp -1
  end


  #
  # Base Game
  #
  
  class Cellar < Card
    set :base
    type :action
    cost 2
    actions 1

    def on_play
      cards = choose_cards "Choose any number of cards to discard", :from => :hand
      discard cards
      draw cards.count
    end
  end
  
  class Chapel < Card
    set :base
    type :action
    cost 2
    
    def on_play
      cards = choose_cards "Choose up to 4 cards to trash", :from => :hand, :max => 4
      cards.each do |card|
        trash card
      end
    end
  end
  
  class Moat < Card
    set :base
    type :action, :reaction
    cost 2

    def on_attack
      if !player.attack_prevented
        if ask "Reveal Moat?"
          player.attack_prevented = true
        end
      end
    end
  end
  
  class Chancellor < Card
    set :base
    type :action
    cost 3
    coins 2
    
    def on_play
      discard_deck = ask "Immediately put deck into discard pile?"
      if discard_deck
        discard_pile.concat deck
        deck.clear
      end
    end
  end

  class Village < Card
    set :base
    type :action
    cost 3
    cards 1
    actions 2
  end
  
  class Woodcutter < Card
    set :base
    type :action
    cost 3
    coins 2
    buys 1
  end
  
  class Workshop < Card
    set :base
    type :action
    cost 3

    def on_play
      card = choose_card "Choose a card to gain", :from => :supply, :max_cost => 4, :required => true
      gain card
    end
  end
  
  class Bureaucrat < Card
    set :base
    type :action, :attack
    cost 3
    coins 2

    def on_play
      gain Silver, :to => :deck
      attacked_players.each do |player|
        card = player.reveal_from_hand :victory
        player.put card, :to => :deck if card
      end
    end
  end

  class Feast < Card
    set :base
    type :action
    cost 4

    def on_play
      card = choose_card "Choose a card to gain", :from => :supply, :max_cost => 5, :required => true
      gain card
      trash self
    end
  end
  
  class Gardens < Card
    set :base
    type :victory
    cost 4

    def vp
      all_cards.count / 10
    end
  end
  
  class Militia < Card
    set :base
    type :action, :attack
    cost 4
    coins 2

    def on_play
      attacked_players.each do |player|
        hand_size = player.hand.size
        if hand_size > 3
          count = hand_size - 3
          cards = player.choose_cards "Discard #{count} cards", :from => :hand, :count => count
          player.discard cards
        end
      end
    end
  end
  
  class Moneylender < Card
    set :base
    type :action
    cost 4
    
    def on_play
      copper = hand.find {|card| card.is_a? Copper}
      if copper
        trash copper
        add_coins 3
      end
    end
  end
  
  class Remodel < Card
    set :base
    type :action
    cost 4

    def on_play
      card = choose_card "Choose a card to remodel", :from => :hand, :required => true
      if card
        max_cost = card.cost + 2
        new_card = choose_card "Choose a card from the supply costing up to #{max_cost}", :from => :supply, :max_cost => max_cost
        trash card
        gain new_card
      end
    end
  end
  
  class Smithy < Card
    set :base
    type :action
    cost 4
    cards 3
  end

  class Spy < Card
    set :base
    type :action, :attack
    cost 4
    cards 1
    actions 1

    def on_play
      ([current_player] + attacked_players).each do |player|
        card = player.draw_from_deck
        player.reveal card
        choice = choose_one ["Discard", "Put it back"], [:discard, :deck]
        if choice == :discard
          player.discard card
        elsif choice == :deck
          player.put_on_deck card
        end
      end
    end
  end  

  class Thief < Card
    set :base
    type :action, :attack
    cost 4

    def on_play
      attacked_players.each do |player|
        cards = reveal_two_cards_from_deck(player)
        treasure = pick_a_treasure(cards)
        if treasure
          player.trash treasure
          if ask "Gain a #{treasure}?"
            gain treasure.class
          end
        end
        remaining = cards.reject {|c| c == treasure}
        player.discard remaining
      end
    end

    def reveal_two_cards_from_deck(player)
      cards = []
      2.times do
        card = player.draw_from_deck
        cards << card if card
      end
      cards
    end

    def pick_a_treasure(cards)
      treasures = cards.select(&:treasure?)
      return nil unless treasures.any?

      treasures_by_class = treasures.reduce({}) { |h,t| h[t.class] = t; h }
      treasure_classes = treasures_by_class.keys
      treasure_class = choose_one treasure_classes, treasure_classes
      treasures_by_class[treasure_class]
    end
  end
  
  class ThroneRoom < Card
    set :base
  end
  
  class CouncilRoom < Card
    set :base
    type :action
    cost 5
    cards 4
    buys 1
    
    def on_play
      other_players.each do |player|
        player.draw
      end
    end
  end
  
  class Festival < Card
    set :base
    type :action
    cost 5
    actions 2
    coins 2
    buys 1
  end
  
  class Laboratory < Card
    set :base
    type :action
    cost 5
    cards 2
    actions 1
  end
  
  class Library < Card
    set :base
    type :action
    cost 5

    def on_play
      set_aside = []
      while hand.size < 7
        card = draw_from_deck
        break if !card
        if card.action? && ask("Set aside #{card}?")
          set_aside << card
        else
          put_in_hand card
        end
      end
      discard set_aside
    end
  end
  
  class Market < Card
    set :base
    type :action
    cost 5
    cards 1
    actions 1
    coins 1
    buys 1
  end

  class Mine < Card
    set :base
  end
  
  class Witch < Card
    set :base
    type :action, :attack
    cost 5
    cards 2
    
    def on_play
      attacked_players.each do |player|
        player.gain Curse
      end
    end
  end
  
  class Adventurer < Card
    set :base
  end
  

  #
  # Intrigue
  #
  
  class Courtyard < Card
    set :intrigue
  end
  
  class Pawn < Card
    set :intrigue
  end
  
  class SecretChamber < Card
    set :intrigue
    type :action, :reaction
  end
  
  class GreatHall < Card
    set :intrigue
    type :action, :victory
    cost 3
    cards 1
    actions 1
    vp 1
  end
  
  class Masquerade < Card
    set :intrigue
  end
  
  class ShantyTown < Card
    set :intrigue
  end
  
  class Steward < Card
    set :intrigue
  end
  
  class Swindler < Card
    set :intrigue
  end
  
  class WishingWell < Card
    set :intrigue
  end
  
  class Baron < Card
    set :intrigue
  end
  
  class Bridge < Card
    set :intrigue
  end
  
  class Conspirator < Card
    set :intrigue
  end
  
  class Coppersmith < Card
    set :intrigue
  end
  
  class Ironworks < Card
    set :intrigue
  end
  
  class MiningVillage < Card
    set :intrigue
  end
  
  class Scout < Card
    set :intrigue
  end
  
  class Duke < Card
    set :intrigue
  end
  
  class Minion < Card
    set :intrigue
    type :action, :attack
    cost 5

    def on_play
      choice = choose_one ["+2", "Discard hand and draw 4"], [:coins, :discard]
      if choice == :coins
        add_coins 2
      elsif choice == :discard
        discard_hand
        draw 4

        attacked_players.each do |player|
          if player.hand.size > 4
            player.discard_hand
            player.draw 4
          end
        end
      end
    end
  end
  
  class Saboteur < Card
    set :intrigue
  end
  
  class Torturer < Card
    set :intrigue
  end
  
  class TradingPost < Card
    set :intrigue
  end
  
  class Tribute < Card
    set :intrigue
  end
  
  class Upgrade < Card
    set :intrigue
  end
  
  class Harem < Card
    set :intrigue
    type :treasure, :victory
    cost 6
    coins 2
    vp 2
  end
  
  class Nobles < Card
    set :intrigue
    type :action, :victory
    cost 6
    vp 2

    def on_play
      choice = choose_one ["+2 actions", "+3 cards"], [:actions, :cards]
      if choice == :actions
        add_actions 2
      elsif choice == :cards
        draw 3
      end
    end
  end
  
  
  #
  # Seaside
  #
  
  class Embargo < Card
    set :seaside
  end
  
  class Haven < Card
    set :seaside
  end
  
  class Lighthouse < Card
    set :seaside
    type :action, :duration
    cost 2
  end
  
  class NativeVillage < Card
    set :seaside
  end
  
  class PearlDiver < Card
    set :seaside
  end
  
  class Ambassador < Card
    set :seaside
  end
  
  class FishingVillage < Card
    set :seaside
  end
  
  class Lookout < Card
    set :seaside
  end
  
  class Smugglers < Card
    set :seaside
  end
  
  class Warehouse < Card
    set :seaside
  end
  
  class Caravan < Card
    set :seaside
  end
  
  class Cutpurse < Card
    set :seaside
  end
  
  class Island < Card
    set :seaside
  end
  
  class Navigator < Card
    set :seaside
  end
  
  class PirateShip < Card
    set :seaside
  end
  
  class Salvager < Card
    set :seaside
    type :action
    cost 4
    
    def on_play
      card = choose_card "Choose a card to trash", :from => :hand
      if card
        add_coins card.cost
        trash card
      end
    end
  end
  
  class SeaHag < Card
    set :seaside
  end
  
  class TreasureMap < Card
    set :seaside
  end
  
  class Bazaar < Card
    set :seaside
    type :action
    cost 5
    cards 1
    actions 2
    coins 1
  end
  
  class Explorer < Card
    set :seaside
  end
  
  class GhostShip < Card
    set :seaside
  end
  
  class MerchantShip < Card
    set :seaside
  end
  
  class Outpost < Card
    set :seaside
  end
  
  class Tactician < Card
    set :seaside
  end
  
  class Treasury < Card
    set :seaside
  end
  
  class Wharf < Card
    set :seaside
  end
  
  
  #
  # Alchemy
  #

  class Herbalist < Card
    set :alchemy
  end
  
  class Apprentice < Card
    set :alchemy
  end
  
  class Transmute < Card
    set :alchemy
  end
  
  class Vineyard < Card
    set :alchemy
  end
  
  class Apothecary < Card
    set :alchemy
  end
  
  class ScryingPool < Card
    set :alchemy
  end
  
  class University < Card
    set :alchemy
  end
  
  class Alchemist < Card
    set :alchemy
  end
  
  class Familiar < Card
    set :alchemy
    type :action, :attack
    cost 3
    potion true
    cards 1
    actions 1
    
    def on_play
      attacked_players.each do |player|
        player.gain Curse
      end
    end
  end

  class PhilosophersStone < Card
    set :alchemy
  end
  
  class Golem < Card
    set :alchemy
  end
  
  class Possession < Card
    set :alchemy
  end
  
  
  #
  # Prosperity
  #

  class Loan < Card
    set :prosperity
  end
  
  class TradeRoute < Card
    set :prosperity
  end
  
  class Watchtower < Card
    set :prosperity
    type :action, :reaction
    cost 3
  end
  
  class Bishop < Card
    set :prosperity
    type :action
    cost 4
    coins 1

    def on_play
      add_vp_tokens 1
      card = choose_card "Choose a card to trash", :from => :hand
      if card
        add_vp_tokens (card.cost / 2).floor
        trash card
      end
    end
  end

  class Monument < Card
    set :prosperity
    type :action
    cost 4
    coins 2
    
    def on_play
      add_vp_tokens 1
    end
  end
  
  class Quarry < Card
    set :prosperity
  end
  
  class Talisman < Card
    set :prosperity
  end
  
  class WorkersVillage < Card
    set :prosperity
    type :action
    cost 4
    cards 1
    actions 2
    buys 1
  end
  
  class City < Card
    set :prosperity
  end
  
  class Contraband < Card
    set :prosperity
  end
  
  class CountingHouse < Card
    set :prosperity
  end
  
  class Mint < Card
    set :prosperity
  end
  
  class Mountebank < Card
    set :prosperity
    type :action, :attack
    cost 5
    coins 2
    
    def on_play
      attacked_players.each do |player|
        curse = player.reveal_from_hand Curse
        if curse
          player.discard curse
        else
          player.gain Curse
          player.gain Copper
        end
      end
    end
  end
  
  class Rabble < Card
    set :prosperity
  end
  
  class RoyalSeal < Card
    set :prosperity
  end
  
  class Vault < Card
    set :prosperity
  end
  
  class Venture < Card
    set :prosperity
  end
  
  class Goons < Card
    set :prosperity
  end
  
  class GrandMarket < Card
    set :prosperity
    type :action
    cost 6
    cards 1
    actions 1
    coins 2
    buys 1
    
    def can_buy
      !treasures_in_play.any? { |card| card.is_a? Copper }
    end
    
    def on_buy
      raise "Cannot buy GrandMarket when Coppers are in play" unless can_buy
    end
  end

  class Hoard < Card
    set :prosperity
  end
  
  class Bank < Card
    set :prosperity
  end
  
  class Expand < Card
    set :prosperity
  end
  
  class Forge < Card
    set :prosperity
  end
  
  class KingsCourt < Card
    set :prosperity
  end
  
  class Peddler < Card
    set :prosperity
    type :action
    cost 8    # 8* (see below)
    cards 1
    actions 1
    coins 1

    def cost
      if buy_phase?
        num_actions = actions_in_play.size + durations_in_play.size
        [8 - 2 * num_actions, 0].max
      else
        8
      end
    end
  end
  
  
  #
  # Cornucopia
  #

  class Hamlet < Card
    set :cornucopia
  end
  
  class FarmingVillage < Card
    set :cornucopia
  end
  
  class FortuneTeller < Card
    set :cornucopia
  end
  
  class Menagerie < Card
    set :cornucopia
  end
  
  class HorseTraders < Card
    set :cornucopia
    type :action, :reaction
    cost 4
  end
  
  class Remake < Card
    set :cornucopia
  end
  
  class Tournament < Card
    set :cornucopia
  end
  
  class YoungWitch < Card
    set :cornucopia
  end
  
  class Harvest < Card
    set :cornucopia
  end
  
  class HornOfPlenty < Card
    set :cornucopia
  end
  
  class HuntingParty < Card
    set :cornucopia
  end
  
  class Jester < Card
    set :cornucopia
  end
  
  class Fairgrounds < Card
    set :cornucopia
    type :victory
    cost 6
    vp 0      # dynamic (see below)
    
    def vp
      num_unique_cards = all_cards.map {|c| c.class }.uniq.size
      num_unique_cards * 2
    end
  end

  
  #
  # Promo
  #

  class BlackMarket < Card
    set :promo
    # Good luck...
  end
  
  class Envoy < Card
    set :promo
  end
  
  class Stash < Card
    set :promo
  end
  
  class WalledVillage < Card
    set :promo
  end

  class Governor < Card
    set :promo
  end

end
